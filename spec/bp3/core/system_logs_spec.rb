# frozen_string_literal: true

require 'logger'
require 'stringio'

RSpec.describe Bp3::Core::SystemLogs do
  let(:io) { StringIO.new }
  let(:logger) { Logger.new(io, level: Logger::DEBUG, formatter: ->(severity, _, _, msg) { "#{severity} #{msg}\n" }) }
  let(:including_class) { Class.new { include Bp3::Core::SystemLogs } }

  before { allow(described_class).to receive(:rails_logger).and_return(logger) }

  describe 'writing to the Rails log' do
    { log_debug: 'DEBUG', log_info: 'INFO', log_warn: 'WARN', log_error: 'ERROR' }.each do |method, severity|
      it "writes .#{method} at #{severity}" do
        described_class.public_send(method, key: 'a.key', message: 'a message', log_to_db: false)

        expect(io.string).to include("#{severity} SystemLogs, #{method.to_s.delete_prefix('log_')}, a.key, a message")
      end

      it "writes ##{method} at #{severity}" do
        including_class.new.public_send(method, key: 'a.key', message: 'a message', log_to_db: false)

        expect(io.string).to start_with("#{severity} ")
      end
    end

    it 'writes log_exception at ERROR, with the message of the exception' do
      described_class.log_exception(StandardError.new('it broke'), key: 'a.key', log_to_db: false)

      expect(io.string).to include('ERROR SystemLogs, exception, a.key, it broke')
    end

    it 'writes an exception at ERROR whatever the level, and a message alongside it at its own level' do
      described_class.log(level: 'info', key: 'a.key', message: 'a message', exception: StandardError.new('it broke'),
                          log_to_db: false)

      expect(io.string).to include('ERROR SystemLogs, info, a.key, it broke')
      expect(io.string).to include('INFO SystemLogs, info, a.key, a message')
    end

    it 'writes a symbol level at that level' do
      described_class.log(level: :warn, key: 'a.key', message: 'a message', log_to_db: false)

      expect(io.string).to start_with('WARN ')
    end

    it 'writes an unknown level at ERROR without calling a method of that name' do
      allow(logger).to receive(:close)

      described_class.log(level: 'close', key: 'a.key', message: 'a message', log_to_db: false)

      expect(logger).not_to have_received(:close)
      expect(io.string).to include('ERROR SystemLogs, close, a.key, a message')
    end

    it 'leaves out a level below the level of the logger' do
      logger.level = Logger::INFO

      described_class.log_debug(key: 'a.key', message: 'a message', log_to_db: false)
      described_class.log_info(key: 'a.key', message: 'another message', log_to_db: false)

      expect(io.string).not_to include('a message')
      expect(io.string).to include('another message')
    end

    it 'writes nothing with log_to_io: false' do
      described_class.log_error(key: 'a.key', message: 'a message', log_to_db: false, log_to_io: false)

      expect(io.string).to eq('')
    end
  end
end
