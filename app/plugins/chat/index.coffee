define('chat', ()->
	name : 'chat'
	title: 'Chat Room'
	icon: 'icon-chat'
	type: 'plugin'
	init: ()->
		foundry.initialized(@name)
		define_controller()
	inited : ()->
		console.log 'end'
)

# setup controller
define_controller = ()->
	angular.module('foundry').controller('ChatController', [
		'$scope', ($scope)->

			# load messages
			$scope.load = ()->
				console.log 'load all messages'

			$scope.send = ()->
				console.log 'send this'

			$scope.load()

	])