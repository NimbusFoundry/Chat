define('chat', ()->
	name : 'chat'
	title: 'Chat Room'
	icon: 'icon-comment'
	type: 'plugin'
	anchor: '#/chat'
	init: ()->
		self = @
		attrs = ['userId', 'userName', 'ts', 'image', 'content', 'file', 'avatar', 'local']
		foundry.model('Message', attrs, (model)->
			foundry.initialized(self.name)
		)
		define_controller()
	inited : ()->
		console.log 'end'
)

# setup controller
define_controller = ()->
	angular.module('foundry').controller('ChatController', [
		'$scope', '$filter', '$timeout', ($scope, $filter, $timeout)->
			# placeholder
			$scope.messages = []
			$scope.message = ''
			$scope.collaborators = []
			# model
			messageModel = foundry._models['Message']
			messageModel.onUpdate((mode, obj, isLocal)->
				$scope.load()
				if !isLocal
		          $scope.$apply()
			)

			sync_collaborators = ()->
				users = doc.getCollaborators()

				# remove same user for different window -todo
				$scope.collaborators = users

			# load messages
			$scope.load = ()->
				# filter 20 messages
				messages = $filter('orderBy')(messageModel.all(), 'local', false)
				$scope.messages = messages

				$scope.me = null
				# find me
				for user in doc.getCollaborators()
				 	if user.isMe
				 		$scope.me = user
				 		break

				sync_collaborators()
				# adjust the height
				$timeout(()->
					$('.list').css({'max-height': $('.chat-list').height()-150})
					$('.list').scrollTop($('.list')[0].scrollHeight)
				, 0)
				
				return
			$scope.send = ()->
				console.log 'send this'

				return if !$scope.message
				now = new Date()

				data = 
					userId: foundry._current_user.id
					userName: foundry._current_user.name
					content: $scope.message
					ts: now.getTime() + now.getTimezoneOffset()*60000
					avatar: $scope.me.photoUrl
					local: now.getTime()
				messageModel.create(data)

				$scope.message = ''
				$scope.load()

			$scope.is_mine_message = (message)->
				# return if the message belongs to current user or not
				return message.userId is foundry._current_user.id

			# user join or left event
			loadUser = (evt)->
				console.log evt
				sync_collaborators()
				$scope.$apply()

			# add event for user
			doc.addEventListener(gapi.drive.realtime.EventType.COLLABORATOR_JOINED, loadUser);
			doc.addEventListener(gapi.drive.realtime.EventType.COLLABORATOR_LEFT, loadUser);

			$scope.load()

	])

window.onresize = ()->
	$('.list').css({'max-height': $('.chat-list').height()-150})
