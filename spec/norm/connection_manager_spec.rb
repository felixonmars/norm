require 'spec_helper'

module Norm
  describe ConnectionManager do
    subject { ConnectionManager }

    class ConnectionManagerSpecDB
      attr_reader :options
      def initialize(options = {})
        @options = options
      end
    end

    def with_fake_db(&block)
      PG::Connection.stub(:new, ->(options = {}) {
        ConnectionManagerSpecDB.new(options)
      }, &block)
    end

    it 'always has a default connection pool' do
      with_fake_db do
        mgr = subject.new
        mgr.pools.size.must_equal 1
        mgr.pools['default'].must_be_kind_of ConnectionPool
      end
    end

    it 'defaults to pool size and timeout of 5' do
      with_fake_db do
        mgr = subject.new
        default = mgr.pools['default']
        default.instance_variable_get(:@size).must_equal 5
        default.instance_variable_get(:@timeout).must_equal 5
      end
    end

    it 'allows specification of pool size and timeout' do
      with_fake_db do
        mgr = subject.new('default' => {'pool' => 3, 'pool_timeout' => 3})
        default = mgr.pools['default']
        default.instance_variable_get(:@size).must_equal 3
        default.instance_variable_get(:@timeout).must_equal 3
      end
    end

    it 'passes other options to underlying db' do
      with_fake_db do
        mgr = subject.new('default' => {'pool' => 3, 'foo' => 'bar'})
        mgr.pools['default'].with do |default|
          default.db.options.must_equal 'foo' => 'bar'
        end
      end
    end

    describe '#with_connection(s)' do
      let(:spec) { {
        'default' => {'host' => 'zomg.bbq'},
        'reader'  => {'host' => 'foo.bar'},
        'writer'  => {'host' => 'mahna.mahna'}
      } }
      subject { ConnectionManager.new(spec) }

      it 'yields a single connection' do
        with_fake_db do
          subject.with_connections('default') do |default|
            default.db.options['host'].must_equal 'zomg.bbq'
          end
        end
      end

      it 'yields multiple connections' do
        with_fake_db do
          subject.with_connections(
            'default', 'reader', 'writer'
          ) do |default, reader, writer|
            default.db.options['host'].must_equal 'zomg.bbq'
            reader.db.options['host'].must_equal 'foo.bar'
            writer.db.options['host'].must_equal 'mahna.mahna'
          end
        end
      end

      it 'defaults to "default" when called as singular with no arguments' do
        with_fake_db do
          subject.with_connection do |conn|
            conn.db.options['host'].must_equal 'zomg.bbq'
          end
        end
      end

    end

  end
end