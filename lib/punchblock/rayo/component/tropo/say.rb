module Punchblock
  class Rayo
    module Component
      module Tropo
        class Say < ComponentNode
          register :say, :say

          ##
          # Creates an Rayo Say command
          #
          # @param [Hash] options
          # @option options [String, Optional] :text to speak back
          # @option options [String, Optional] :voice with which to render TTS
          # @option options [Audio, Optional] :audio to play
          # @option options [String, Optional] :ssml document to render TTS
          #
          # @return [Rayo::Command::Say] an Rayo "say" command
          #
          # @example
          #   say :text => 'Hello brown cow.'
          #
          #   returns:
          #     <say xmlns="urn:xmpp:tropo:say:1">Hello brown cow.</say>
          #
          def self.new(options = {})
            super().tap do |new_node|
              case options
              when Hash
                new_node.voice = options.delete(:voice) if options[:voice]
                new_node.ssml = options.delete(:ssml) if options[:ssml]
                new_node << options.delete(:text) if options[:text]
                if audio = options[:audio]
                  audio = Audio.new(audio) unless audio.is_a?(Audio)
                  new_node << audio
                end
              when Nokogiri::XML::Element
                new_node.inherit options
              end
            end
          end

          ##
          # @return [String] the TTS voice to use
          #
          def voice
            read_attr :voice
          end

          ##
          # @param [String] voice to use when rendering TTS
          #
          def voice=(voice)
            write_attr :voice, voice
          end

          ##
          # @return [String] the SSML document to render TTS
          #
          def ssml
            content.strip
          end

          ##
          # @param [String] ssml the SSML document to render TTS
          #
          def ssml=(ssml)
            if ssml.instance_of?(String)
              self << RayoNode.new('').parse(ssml) do |config|
                config.noblanks.strict
              end
            end
          end

          def inspect_attributes # :nodoc:
            [:voice, :audio, :ssml] + super
          end

          state_machine :state do
            event :paused do
              transition :executing => :paused
            end

            event :resumed do
              transition :paused => :executing
            end
          end

          # Pauses a running Say
          #
          # @return [Rayo::Command::Say::Pause] an Rayo pause message for the current Say
          #
          # @example
          #    say_obj.pause_action.to_xml
          #
          #    returns:
          #      <pause xmlns="urn:xmpp:tropo:say:1"/>
          def pause_action
            Pause.new :component_id => component_id, :call_id => call_id
          end

          ##
          # Sends an Rayo pause message for the current Say
          #
          def pause!
            raise InvalidActionError, "Cannot pause a Say that is not executing" unless executing?
            pause_action.tap do |action|
              result = write_action action
              paused! if result
            end
          end

          ##
          # Create an Rayo resume message for the current Say
          #
          # @return [Rayo::Command::Say::Resume] an Rayo resume message
          #
          # @example
          #    say_obj.resume_action.to_xml
          #
          #    returns:
          #      <resume xmlns="urn:xmpp:tropo:say:1"/>
          def resume_action
            Resume.new :component_id => component_id, :call_id => call_id
          end

          ##
          # Sends an Rayo resume message for the current Say
          #
          def resume!
            raise InvalidActionError, "Cannot resume a Say that is not paused." unless paused?
            resume_action.tap do |action|
              result = write_action action
              resumed! if result
            end
          end

          class Pause < Action # :nodoc:
            register :pause, :say
          end

          class Resume < Action # :nodoc:
            register :resume, :say
          end

          class Complete
            class Success < Rayo::Event::Complete::Reason
              register :success, :say_complete
            end
          end
        end # Say
      end # Tropo
    end # Command
  end # Rayo
end # Punchblock
