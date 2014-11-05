define('chat', ()->
	title: 'Chat Room'
	icon: 'icon-comment'
	type: 'plugin'
	anchor: '#/chat'
	init: ()->
		self = @
		attrs = ['userId', 'userName', 'ts', 'image', 'content', 'file', 'avatar', 'local']
		foundry.model('Message', attrs, (model)->
			foundry.initialized('chat')
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
				$scope.$apply()
			)

			sync_collaborators = ()->
				Nimbus.realtime.getCollaborators((users)->
					# remove same user for different window -todo
					$scope.collaborators = users
				)

			# load messages
			$scope.load = ()->
				# filter 20 messages
				messages = $filter('orderBy')(messageModel.all(), 'local', false)
				$scope.messages = messages

				$scope.me = null
				# find me
				Nimbus.realtime.getCollaborators((users)->
					for user in users
						if user.isMe
					 		$scope.me = user
					 		break
				)

				sync_collaborators()
				# adjust the height
				#$timeout(()->
				#	$('.list').css({'max-height': $('.chat-list').height()-160})
				#	$('.list').scrollTop($('.list')[0].scrollHeight)
				#, 100)
				
				return
			$scope.send = ()->
				console.log 'send this'

				return if !$scope.message
				now = new Date()

				data = 
					userId: foundry._current_user.id
					userName: foundry._current_user.name || foundry._current_user.displayName
					content: $scope.message
					ts: now.getTime() + now.getTimezoneOffset()*60000
					avatar: $scope.me.photoUrl || 'assets/img/photo.jpg'
					local: now.getTime()
				messageModel.create(data)

				$scope.message = ''
				$scope.load()

			$scope.is_mine_message = (message)->
				# return if the message belongs to current user or not
				return message.userId is foundry._current_user.id

			# user join or left event
			loadUser = (evt)->
				console.log evt.type
				sync_collaborators()
				$scope.$apply()

			# add event for user
			# Nimbus.realtime.doc.addEventListener(gapi.drive.realtime.EventType.COLLABORATOR_JOINED, loadUser);
			# Nimbus.realtime.doc.addEventListener(gapi.drive.realtime.EventType.COLLABORATOR_LEFT, loadUser);

			$scope.load()

	])

#window.onresize = ()->
#	$('.list').css({'max-height': $('.chat-list').height()-150})
	angular.module('foundry').run(['$templateCache', ($templateCache)->
		html = '<link href="https://raw.githubusercontent.com/NimbusFoundry/Chat/firebase/assets/css/style.css">
				<div ng-controller="ChatController">
					<div class="breadcrumb absolute">
				        <h1>Chat Room</h1>
				    </div>  
					<div class="container-fluid">
						<div class="row-fluid">
						
							<!-- message list  -->
							<div class="chat-list span8">
								<div class="list">
									<div ng-repeat="message in messages" class="msg" ng-class="{mine:is_mine_message(message)}">
										<div class="avatar">
											<img ng-src="{{message.avatar || '+"'https://raw.githubusercontent.com/NimbusFoundry/Chat/firebase/assets/img/photo.jpg'"+'}}" alt="">
										</div>
										<div class="message-content">
											<p ng-bind="message.content" class="content" ng-if="message.content">
												
											</p>
											<p ng-if="message.image">
												<!-- image template -->
											</p>
											<p ng-if="message.file">
												<!-- file template -->
											</p>
											<p class="muted">
												<strong ng-bind="message.userName" class="bold"></strong> •
												<span ng-bind="message.local|date:'+"'MM-dd HH:mm:ss'"+'"></span>
											</p>
										</div>

									</div>
								</div>
								<div class="send-box">
									<div class="send-container">
										<textarea ng-model="message">
											
										</textarea>
										<button type="button" ng-click="send()" value="Send">Send</button>
									</div>
								</div>
							</div>
							<!-- online user list -->
							<div class="user-list span4" style="margin-top: 10px;">
								
								<ul style="list-style:none;">
									<p style="font-weight: bold; color: #777;">Current people: </p>
									<li ng-repeat="user in collaborators|orderBy:'+"'displayName'"+'">
										<!-- user list template -->
										<img ng-src="{{user.photoUrl}}" alt="" style="max-width: 50px;">
										<span ng-bind="user.displayName"></span>
									</li>
								</ul>
							</div>
				    	</div>
					</div>
				</div>'
		$templateCache.put('app/plugins/chat/index.html', html)
	])