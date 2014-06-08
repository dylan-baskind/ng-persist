angular.module("ngPersist", []).factory("Persist", function($http, log) {
  var Persist, debug;
  debug = false;
  return Persist = (function() {
    function Persist(options) {
      this.watchObject = options.watchObject;
      this.scope = options.scope;
      this.apiRoute = options.apiRoute;
      this.throttling = options.throttling || 500;
      this.payloadName = options.payloadName || 'content';
      this.dataTransformer = options.dataTransformer;
      this.validation = options.validation;
      this.watch();
    }

    Persist.prototype.update = function(watchObject) {
      if (debug) {
        log.at("Persist Update");
      }
      if (this.validation != null) {
        if (debug) {
          log.note("Have validation object");
        }
        if (!this.validation(watchObject)) {
          if (debug) {
            log.error("Validation failed");
          }
          return;
        }
      }
      watchObject = this.ensureObject(watchObject);
      if (this.dataTransformer != null) {
        watchObject = this.dataTransformer(watchObject);
      }
      if (this.apiRoute.indexOf('undefined') !== -1) {
        if (debug) {
          log.error("Undefined value in the API URL");
        }
        return;
      }
      if (debug) {
        log.note("API Path:", this.apiRoute);
        log.say("Watch Object:", this.watchObject);
      }
      if (debug) {
        log.doing("Performing Update...");
      }
      return $http.post(this.apiRoute, watchObject).success(function(result) {
        if (debug) {
          log.success("Update Succeeded");
          return log.say("Returned From Server: ", result.data);
        }
      }).error(function(error) {
        return log.error(error);
      });
    };

    Persist.prototype.ensureObject = function(watchObject) {
      var data;
      if (_.isString(watchObject)) {
        data = {};
        data[this.payloadName] = watchObject;
        return data;
      } else {
        return watchObject;
      }
    };

    Persist.prototype.watch = function() {
      var debounced;
      debounced = _.debounce(((function(_this) {
        return function(watchObject) {
          return _this.update(watchObject);
        };
      })(this)), this.throttling, {
        trailing: true
      });
      return this.scope.$watch(this.watchObject, debounced, true);
    };

    return Persist;

  })();
});