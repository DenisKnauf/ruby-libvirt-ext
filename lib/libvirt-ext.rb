require 'libvirt'
require 'enum'
require 'uuidtools'

class Enum
	class <<self
		alias [] find
	end
end

module Libvirt
	class <<self
		def ensure_close_if_block_given c
			if block_given?
				begin yield c
				ensure c.close
				end
			else
				c
			end
		end

		def connect uri = nil, &e
			ensure_close_if_block_given open( uri), &e
		end

		def connect_read_only uri = nil, &e
			ensure_close_if_block_given open_read_only( uri), &e
		end
	end

	class Connect
		def each_active_domain
			return Enumerator.new( self, __callee__)  unless block_given?
			list_domains.each {|id| yield lookup_domain_by_id( id) }
		end

		def each_inactive_domain
			return Enumerator.new( self, __callee__)  unless block_given?
			list_defined_domains.each {|name| yield lookup_domain_by_name( name) }
		end

		def each_domain &e
			return Enumerator.new( self, __callee__)  unless block_given?
			each_active_domain &e
			each_inactive_domain &e
		end

		def active_domains()  each_active_domain.to_a  end
		def inactive_domains()  each_inactive_domain.to_a  end
		def domains()  each_domain.to_a  end
		def lookup_domain id_uuid_or_name
			case id_uuid_or_name
			when UUIDTools::UUID then lookup_domain_by_uuid id_uuid_or_name.to_s
			when Numeric then lookup_domain_by_id id_uuid_or_name
			when String
				begin UUIDTools::UUID.parse id_uuid_or_name
				rescue Object
					if id_uuid_or_name == id_uuid_or_name.to_i.to_s
						lookup_domain_by_id id_uuid_or_name
					else
						lookup_domain_by_name id_uuid_or_name
					end
				end
			else raise ArgumentError, "UUID or domain name expected."
			end
		end

		def inspect
			"#<#{self.class.name} #{uri}>"
		end
	end

	class Domain
		class CloseReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Error     'misc I/O Error'
				EOF       'end-of-file from server'
				KeepAlive 'keepalive timer triggered'
				Client    'client requested it'
				Last      '--'
			end
		end

		class BlockedReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown 'unknown reason'
				Last   '--'
			end
		end

		class CrashedReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown 'unknown reason'
				Last   '--'
			end
		end

		class NostateReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown 'unknown reason'
				Last   '--'
			end
		end

		class PMSuspendedReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown 'unknown reason'
				Last   '--'
			end
		end

		class PMSuspendedDiskReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown 'unknown reason'
				Last   '--'
			end
		end

		class PausedReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown       'unknown reason'
				User         'paused on user request'
				Migration    'paused for offline migration'
				Save         'paused for save'
				Dump         'paused for offline core dump'
				IOError      'paused due to a disk I/O error'
				Watchdog     'paused due to a watchdog event'
				FromSnapshot 'paused after restoring from snapshot'
				ShuttingDown 'paused during shutdown process'
				Snapshot     'paused while creating a snapshot'
				Last         '--'
			end
		end

		class RunningReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unknown      'unknown reason'
				Booted       'normal startup from boot'
				Migrated     'migrated from another host'
				Restored     'restored from a state file'
				FromSnapshot 'restored from snapshot'
				Unpaused     'returned from paused state'
				MigrationCanceled 'returned from migration'
				SaveCaneled  'returned from failed save process'
				Wakeup       'returned from pmsuspended due to wakeup event'
				Last         '--'
			end
		end

		class ShutdownReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown 'unknown reason'
				User   'shutting down on user request'
				Last   '--'
			end
		end

		class ShutoffReason < Enum
			enum_fields :comment
			start_at 0
			enum do
				Unkown       'unknown reason'
				Shutdown     'normal shutdown'
				Destroyed    'forced poweroff'
				Crashed      'domain crashed'
				Migrated     'migrated to another host'
				Saved        'saved to a file'
				Failed       'domain failed to start'
				FromSnapshot 'restored from a snapshot which was taken while domain was shutoff'
				Last         '--'
			end
		end

		class State < Enum
			enum_fields :comment, :reasons
			start_at 0
			enum do 
				Nostate     'No state', NostateReason
				Running     'The domain is running', RunningReason
				Blocked     'The domain is blocked on resource', BlockedReason
				Paused      'The domain is paused by user', PausedReason
				Shutdown    'The domain is being shut down', ShutdownReason
				Shutoff     'The domain is shut off', ShutoffReason
				Crashed     'The domain is crashed', CrashedReason
				PMSuspended 'The domain is suspended by guest power management', PMSuspendedReason
				Last        '--'
			end

			def self.[] *s
				state, reason = s.flatten
				state = find state
				if reason
					[state, state.reasons.find( reason)]
				else state
				end
			end
		end

		def state_reason
			State[self.state]
		end

		def inspect
			state, reason = state_reason
			"#<#{self.class.name}: #{uuid} #{name} #{state.title}[#{reason.title}]>"
		end
	end
end
