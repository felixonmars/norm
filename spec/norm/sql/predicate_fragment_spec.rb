require 'spec_helper'

module Norm
  module SQL
    describe PredicateFragment do
      subject { PredicateFragment }

      it 'defaults to empty sql' do
        subject.new.sql.must_equal ''
      end

      it 'defaults to empty params' do
        subject.new.params.must_equal []
      end

      it 'allows specification of custom SQL' do
        subject.new('select 1').sql.must_equal 'select 1'
      end

      it 'casts sql param to string' do
        subject.new(1).sql.must_equal '1'
      end

      it 'allows specification of custom params' do
        subject.new('', 'zomg').params.must_equal(['zomg'])
      end

      it 'allows interpolation of hash params' do
        fragment = subject.new('$foo', :foo => 'bar')
        fragment.sql.must_equal '$?'
        fragment.params.must_equal ['bar']
      end

      it 'allows interpolation of nested hash params' do
        fragment = subject.new(
          '$foo.bar.baz', :foo => {:bar => {:baz => 'qux'}}
        )
        fragment.sql.must_equal '$?'
        fragment.params.must_equal ['qux']
      end

      it 'raises MissingInterpolationError if a missing key is referenced' do
        error = proc { subject.new('$foo.bar', :foo => {}) }.must_raise(
          MissingInterpolationError
        )
        error.message.must_equal 'Missing content for "foo.bar".'
      end

      it 'allows escaping of interpolation with backslash' do
        fragment = subject.new('\\$foo', {})
        fragment.sql.must_equal '$foo'
        fragment.params.must_equal []
      end

      describe 'with a hash param' do

        it 'builds sql/params with equality predicates' do
          fragment = subject.new(:id => 1)
          fragment.sql.must_equal '"id" = $?'
          fragment.params.must_equal [1]
        end

        it 'builds sql/params with "IS NULL" if a nil is on RHS' do
          fragment = subject.new(:id => nil)
          fragment.sql.must_equal '"id" IS NULL'
          fragment.params.must_be :empty?
        end

        it 'builds sql/params with IN if an array is on RHS' do
          fragment = subject.new(:id => [1, 2])
          fragment.sql.must_equal '"id" IN ($?, $?)'
          fragment.params.must_equal [1, 2]
        end

        it 'builds sql/params with FALSE if an array with nil is on RHS' do
          fragment = subject.new(:id => [1, nil])
          fragment.sql.must_equal 'FALSE /* IN with NULL value is never TRUE */'
          fragment.params.must_be :empty?
        end

      end

    end
  end
end
