// Generated by CoffeeScript 1.8.0
(function() {
  var define_controller;

  define('chat', function() {
    return {
      title: 'Chat Room',
      icon: 'icon-comment',
      type: 'plugin',
      anchor: '#/chat',
      init: function() {
        var attrs, self;
        self = this;
        attrs = ['userId', 'userName', 'ts', 'image', 'content', 'file', 'avatar', 'local'];
        foundry.model('Message', attrs, function(model) {
          return foundry.initialized('chat');
        });
        return define_controller();
      },
      inited: function() {
        return console.log('end');
      }
    };
  });

  define_controller = function() {
    angular.module('foundry').controller('ChatController', [
      '$scope', '$filter', '$timeout', function($scope, $filter, $timeout) {
        var loadUser, messageModel, sync_collaborators;
        $scope.messages = [];
        $scope.message = '';
        $scope.collaborators = [];
        messageModel = foundry._models['Message'];
        messageModel.onUpdate(function(mode, obj, isLocal) {
          $scope.load();
          return $scope.$apply();
        });
        sync_collaborators = function() {
          return Nimbus.realtime.getCollaborators(function(users) {
            return $scope.collaborators = users;
          });
        };
        $scope.load = function() {
          var messages;
          messages = $filter('orderBy')(messageModel.all(), 'local', false);
          $scope.messages = messages;
          $scope.me = null;
          Nimbus.realtime.getCollaborators(function(users) {
            var user, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = users.length; _i < _len; _i++) {
              user = users[_i];
              if (user.isMe) {
                $scope.me = user;
                break;
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          });
          sync_collaborators();
        };
        $scope.send = function() {
          var data, now;
          console.log('send this');
          if (!$scope.message) {
            return;
          }
          now = new Date();
          data = {
            userId: foundry._current_user.id,
            userName: foundry._current_user.name || foundry._current_user.displayName,
            content: $scope.message,
            ts: now.getTime() + now.getTimezoneOffset() * 60000,
            avatar: $scope.me.photoUrl || 'assets/img/photo.jpg',
            local: now.getTime()
          };
          messageModel.create(data);
          $scope.message = '';
          return $scope.load();
        };
        $scope.is_mine_message = function(message) {
          return message.userId === foundry._current_user.id;
        };
        loadUser = function(evt) {
          console.log(evt.type);
          sync_collaborators();
          return $scope.$apply();
        };
        return $scope.load();
      }
    ]);
    return angular.module('foundry').run([
      '$templateCache', function($templateCache) {
        var html;
        html = '<link href="https://raw.githubusercontent.com/NimbusFoundry/Chat/firebase/assets/css/style.css"> <div ng-controller="ChatController"> <div class="breadcrumb absolute"> <h1>Chat Room</h1> </div> <div class="container-fluid"> <div class="row-fluid"> <!-- message list  --> <div class="chat-list span8"> <div class="list"> <div ng-repeat="message in messages" class="msg" ng-class="{mine:is_mine_message(message)}"> <div class="avatar"> <img ng-src="{{message.avatar || ' + "'https://raw.githubusercontent.com/NimbusFoundry/Chat/firebase/assets/img/photo.jpg'" + '}}" alt=""> </div> <div class="message-content"> <p ng-bind="message.content" class="content" ng-if="message.content"> </p> <p ng-if="message.image"> <!-- image template --> </p> <p ng-if="message.file"> <!-- file template --> </p> <p class="muted"> <strong ng-bind="message.userName" class="bold"></strong> • <span ng-bind="message.local|date:' + "'MM-dd HH:mm:ss'" + '"></span> </p> </div> </div> </div> <div class="send-box"> <div class="send-container"> <textarea ng-model="message"> </textarea> <button type="button" ng-click="send()" value="Send">Send</button> </div> </div> </div> <!-- online user list --> <div class="user-list span4" style="margin-top: 10px;"> <ul style="list-style:none;"> <p style="font-weight: bold; color: #777;">Current people: </p> <li ng-repeat="user in collaborators|orderBy:' + "'displayName'" + '"> <!-- user list template --> <img ng-src="{{user.photoUrl}}" alt="" style="max-width: 50px;"> <span ng-bind="user.displayName"></span> </li> </ul> </div> </div> </div> </div>';
        return $templateCache.put('app/plugins/chat/index.html', html);
      }
    ]);
  };

}).call(this);
