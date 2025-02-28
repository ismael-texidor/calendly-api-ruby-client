# frozen_string_literal: true

require 'calendly/client'
require 'calendly/models/model_utils'

module Calendly
  # Calendly's user model.
  # Primary account details of a specific user.
  class User
    include ModelUtils
    UUID_RE = %r{\A#{Client::API_HOST}/users/(\w+)\z}.freeze
    TIME_FIELDS = %i[created_at updated_at].freeze
    ASSOCIATION = {current_organization: Organization}.freeze

    # @return [String]
    # unique id of the User object.
    attr_accessor :uuid

    # @return [String]
    # Canonical resource reference.
    attr_accessor :uri

    # @return [String]
    # User's human-readable name.
    attr_accessor :name

    # @return [String]
    # Unique readable value used in page URL.
    attr_accessor :slug

    # @return [String]
    # User's email address.
    attr_accessor :email

    # @return [String]
    # URL of user's avatar image.
    attr_accessor :avatar_url

    # @return [String]
    # URL of user's event page.
    attr_accessor :scheduling_url

    # @return [String]
    # Timezone offest to use when presenting time information to user.
    attr_accessor :timezone

    # @return [Time]
    # Moment when user record was first created.
    attr_accessor :created_at

    # @return [Time]
    # Moment when user record was last updated.
    attr_accessor :updated_at

    # @return [Organization]
    # user's current organization
    attr_accessor :current_organization

    #
    # Get basic information associated with self.
    #
    # @return [Calendly::User]
    # @raise [Calendly::Error] if the uuid is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.1.0
    def fetch
      client.user uuid
    end

    #
    # Get an organization membership information associated with self.
    #
    # @return [Calendly::OrganizationMembership]
    # @raise [Calendly::Error] if the uri is empty.
    # @since 0.1.0
    def organization_membership
      if defined?(@cached_organization_membership) && @cached_organization_membership
        return @cached_organization_membership
      end

      mems, = client.memberships_by_user uri
      @cached_organization_membership = mems.first
    end

    # @since 0.2.0
    def organization_membership!
      @cached_organization_membership = nil
      organization_membership
    end

    #
    # Returns all Event Types associated with self.
    #
    # @param [Hash] opts the optional request parameters.
    # @option opts [Integer] :count Number of rows to return.
    # @option opts [String] :page_token Pass this to get the next portion of collection.
    # @option opts [String] :sort Order results by the specified field and direction.
    # Accepts comma-separated list of {field}:{direction} values.
    # @return [Array<Calendly::EventType>]
    # @raise [Calendly::Error] if the uri is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.1.0
    def event_types(opts = {})
      return @cached_event_types if defined?(@cached_event_types) && @cached_event_types

      request_proc = proc { |options| client.event_types_by_user uri, options }
      @cached_event_types = auto_pagination request_proc, opts
    end

    # @since 0.2.0
    def event_types!(opts = {})
      @cached_event_types = nil
      event_types opts
    end

    #
    # Returns all Scheduled Events associated with self.
    #
    # @param [Hash] opts the optional request parameters.
    # @option opts [Integer] :count Number of rows to return.
    # @option opts [String] :invitee_email Return events scheduled with the specified invitee email
    # @option opts [String] :max_start_timeUpper bound (inclusive) for an event's start time to filter by.
    # @option opts [String] :min_start_time Lower bound (inclusive) for an event's start time to filter by.
    # @option opts [String] :page_token Pass this to get the next portion of collection.
    # @option opts [String] :sort Order results by the specified field and directin.
    # Accepts comma-separated list of {field}:{direction} values.
    # @option opts [String] :status Whether the scheduled event is active or canceled
    # @return [Array<Calendly::Event>]
    # @raise [Calendly::Error] if the uri is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.1.0
    def scheduled_events(opts = {})
      return @cached_scheduled_events if defined?(@cached_scheduled_events) && @cached_scheduled_events

      request_proc = proc { |options| client.scheduled_events_by_user uri, options }
      @cached_scheduled_events = auto_pagination request_proc, opts
    end

    # @since 0.2.0
    def scheduled_events!(opts = {})
      @cached_scheduled_events = nil
      scheduled_events opts
    end

    #
    # Get List of user scope Webhooks associated with self.
    #
    # @param [Hash] opts the optional request parameters.
    # @option opts [Integer] :count Number of rows to return.
    # @option opts [String] :page_token Pass this to get the next portion of collection.
    # @option opts [String] :sort Order results by the specified field and directin. Accepts comma-separated list of {field}:{direction} values.
    # Accepts comma-separated list of {field}:{direction} values.
    # @return [Array<Calendly::WebhookSubscription>]
    # @raise [Calendly::Error] if the organization.uri is empty.
    # @raise [Calendly::Error] if the uri is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.6.0
    def webhooks(opts = {})
      return @cached_webhooks if defined?(@cached_webhooks) && @cached_webhooks

      org_uri = current_organization&.uri
      request_proc = proc { |options| client.user_scope_webhooks org_uri, uri, options }
      @cached_webhooks = auto_pagination request_proc, opts
    end

    # @since 0.6.0
    def webhooks!(opts = {})
      @cached_webhooks = nil
      webhooks opts
    end

    #
    # Create a user scope webhook associated with self.
    #
    # @param [String] url Canonical reference (unique identifier) for the resource.
    # @param [Array<String>] events List of user events to subscribe to. options: invitee.created or invitee.canceled
    # @return [Calendly::WebhookSubscription]
    # @raise [Calendly::Error] if the url arg is empty.
    # @raise [Calendly::Error] if the events arg is empty.
    # @raise [Calendly::Error] if the organization.uri is empty.
    # @raise [Calendly::ApiError] if the api returns error code.
    # @since 0.6.0
    def create_webhook(url, events)
      org_uri = current_organization&.uri
      client.create_webhook url, events, org_uri, uri
    end
  end
end
