require 'spec_helper'

module Norm
  describe Repository do
    subject { Class.new(Repository) }

    it 'requires a record class be set' do
      proc { subject.new.record_class }.must_raise NotImplementedError
    end

    it 'defaults PKs to the identifying attribute names of the record class' do
      record_class = Class.new(Record)
      subject.record_class = record_class
      subject.new.primary_keys.must_equal(
        record_class.identifying_attribute_names
      )
    end

    it 'allows setting an alternate list of primary keys with .primary_keys=' do
      subject.primary_keys = [:name, :age]
      subject.new.primary_keys.must_equal ['name', 'age']
    end

    it 'allows setting an alternate list of primary keys with .primary_key=' do
      subject.primary_key = :name
      subject.new.primary_keys.must_equal ['name']
    end

    describe 'storage methods' do
      subject { Class.new(Repository).new }

      it 'requires subclasses to implement #all' do
        proc { subject.all }.must_raise NotImplementedError
      end

      it 'requires subclasses to implement #fetch' do
        proc { subject.fetch 1 }.must_raise NotImplementedError
      end

      it 'requires subclasses to implement #store' do
        proc { subject.store(nil) }.must_raise NotImplementedError
      end

      it 'requires subclasses to implement #insert' do
        proc { subject.insert(nil) }.must_raise NotImplementedError
      end

      it 'requires subclasses to implement #update' do
        proc { subject.update(nil) }.must_raise NotImplementedError
      end

      it 'requires subclasses to implement #delete' do
        proc { subject.delete(nil) }.must_raise NotImplementedError
      end

    end

  end
end
