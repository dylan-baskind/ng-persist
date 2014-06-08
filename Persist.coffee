# Persistence Module
angular.module "ngPersist", []
.factory "Persist", ($http, Saving, log) ->
	debug = no

	class Persist
		constructor: (options) ->
			@watchObject = options.watchObject
			@scope = options.scope
			@apiRoute = options.apiRoute
			@throttling = options.throttling or 500
			@payloadName = options.payloadName or 'content'
			@dataTransformer = options.dataTransformer
			@validation = options.validation

			# Start watching!
			@watch()

		# Update DB
		update: (watchObject) ->

			# Debug
			if debug then log.at "Persist Update"

			# Check validation
			if @validation?
				if debug then log.note "Have validation object"
				unless @validation watchObject
					if debug then log.error "Validation failed"
					return

			# Make sure we pass an object, not a string
			watchObject = @ensureObject(watchObject)

			# If we've been supplied with a data transformation function
			if @dataTransformer?
				watchObject = @dataTransformer( watchObject )

			# Abort if we've got an "undefined" in the url
			unless @apiRoute.indexOf('undefined') is -1
				if debug then log.error "Undefined value in the API URL"
				return

			# Debug
			if debug
				log.note "API Path:", @apiRoute
				log.say "Watch Object:", @watchObject

			# New Saving State
			saving = new Saving()

			# Perform update...
			if debug then log.doing "Performing Update..."
			$http
				.post @apiRoute, watchObject
				.success (result) ->
					
					# Mark Saving state as done.
					saving.done()

					# Debug msg
					if debug
						log.success "Update Succeeded"
						log.say "Returned From Server: ", result.data
				.error (error) ->
					log.error( error )
					# Error State :(
					saving.error()
					

		# Ensure we've got an object, not a string
		ensureObject: (watchObject) ->
			if _.isString( watchObject )
				data = {}
				data[@payloadName] = watchObject
				return data
			else
				return watchObject


		# Setup the watcher
		watch: ->
			# Setup Debounced Function
			debounced =
				_.debounce(
					( (watchObject) => @update(watchObject) ),
					@throttling,
					trailing:yes
				)
			
			# Start watching
			@scope.$watch( @watchObject, debounced, yes)



