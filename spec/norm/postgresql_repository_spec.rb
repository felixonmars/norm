require 'spec_helper'

module Norm
  describe PostgreSQLRepository do

    let(:person_record_class) {
      Class.new(Record) do
        attribute :id,          Attr::Integer
        attribute :name,        Attr::String
        attribute :age,         Attr::Integer
        attribute :created_at,  Attr::Timestamp
        attribute :updated_at,  Attr::Timestamp
      end
    }
    subject {
      record_class = person_record_class
      Class.new(PostgreSQLRepository) {
        self.record_class = record_class

        def select_statement
          Norm::Statement.select.from('people')
        end

        def insert_statement
          column_list = record_class.attribute_names.join(', ')
          Norm::Statement.insert("people (#{column_list})").returning('*')
        end

        def update_statement
          Norm::Statement.update('people').returning('*')
        end

        def delete_statement
          Norm::Statement.delete('people').returning('*')
        end

      }.new
    }

    before {
      Norm.with_connection do |conn|
        conn.exec_string('truncate table people restart identity')
      end
    }

    describe '#all' do

      it 'returns a list of all records in the store' do
        subject.all.must_equal []
        subject.insert(person_record_class.new(:name => 'Ernie', :age => 36))
        subject.all.size.must_equal 1
        subject.all.first.must_be_kind_of person_record_class
      end

    end

    describe '#insert' do

      it 'inserts a new record' do
        person = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(person)
        records = subject.all
        records.size.must_equal 1
        person = records.first
        person.id.must_equal 1
        person.name.must_equal 'Ernie'
        person.age.must_equal 36
        person.created_at.must_be_kind_of Attr::Timestamp
        person.updated_at.must_be_kind_of Attr::Timestamp
      end

      it 'raises PG::NotNullViolation if a nil value is supplied for a key' do
        skip 'what do we really want to do here?'
        person = person_record_class.new(:id => nil, :name => 'Ernie')
        proc { subject.insert(person) }.must_raise(PG::NotNullViolation)
      end

      it 'raises PG::UniqueViolation if a record with that key exists' do
        skip 'what do we really want to do here?'
        person1 = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(person1)
        person2 = person_record_class.new(:id => person1.id, :name => 'Bert')
        proc { subject.insert(person2) }.must_raise(PG::UniqueViolation)
      end

    end

    describe '#update' do

      it 'updates a stored record' do
        person = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(person)
        person = subject.fetch(person.id)
        person.name = 'Bert'
        previous_updated_at = person.updated_at
        subject.update(person)
        person = subject.fetch(person.id)
        person.name.must_equal 'Bert'
        person.updated_at.must_be :>, previous_updated_at
      end

      it 'sets updated attributes on the passed-in records' do
        ernie = person_record_class.new(:name => 'Ernie', :age => 36)
        bert  = person_record_class.new(:name => 'Bert', :age => 37)
        subject.insert([ernie, bert])
        ernie_updated = ernie.updated_at
        bert_updated  = bert.updated_at
        ernie.name, bert.name = bert.name, ernie.name
        subject.update([ernie, bert])
        ernie.updated_at.must_be :>, ernie_updated
        bert.updated_at.must_be :>, bert_updated
        ernie.name.must_equal 'Bert'
        bert.name.must_equal 'Ernie'
      end

      it 'does nothing if the record has not been updated' do
        ernie = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(ernie)
        updated_at = ernie.updated_at
        subject.update(ernie)
        ernie.updated_at.must_equal updated_at
      end

      it 'raises InvalidKeyError if the record has a nil value in its key' do
        skip 'what do we really want to do here?'
        person = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(person)
        person.id = nil
        proc { subject.update(person) }.must_raise(
          InvalidKeyError
        )
      end

      it 'raises NotFoundError if the record being updated is not present' do
        skip 'what do we really want to do here?'
        person = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(person)
        person.id = 42
        proc { subject.update(person) }.must_raise(
          NotFoundError
        )
      end

    end

    describe '#fetch' do

      it 'fetches a stored record' do
        person = person_record_class.new(:name => 'Ernie', :age => 36)
        subject.insert(person)
        person = subject.fetch(person.id)
        person.name.must_equal 'Ernie'
        person.age.must_equal 36
        person.created_at.must_be_kind_of Attr::Timestamp
        person.updated_at.must_be_kind_of Attr::Timestamp
      end

    end

    describe '#delete' do

      it 'deletes a stored record' do
        ernie = person_record_class.new(:name => 'Ernie', :age => 36)
        bert = person_record_class.new(:name => 'Bert', :age => 37)
        subject.store([ernie, bert])
        subject.delete(ernie)
        subject.fetch(ernie.id).must_be_nil
        bert = subject.fetch(bert.id)
        ernie.must_be :deleted?
        ernie.wont_be :stored?
        bert.must_be :stored?
        bert.wont_be :deleted?
      end

    end

    describe '#store' do

      it 'updates and inserts records as appropriate' do
        ernie = person_record_class.new(:name => 'Ernie', :age => 36)
        bert = person_record_class.new(:name => 'Bert', :age => 37)
        subject.insert(ernie)
        ernie.age = 37
        previous_updated_at = ernie.updated_at
        subject.store([ernie, bert])
        ernie.updated_at.must_be :>, previous_updated_at
        bert.must_be :stored?
      end

    end

  end
end