define('workspaces', ['require','core/analytic'],(require, analytic)->
	c_file = Nimbus.realtime.c_file
	doc_plugin=
		type : 'plugin'
		order : -13
		icon : 'icon-folder-close'
		_app_files : []
		_app_folders : []
		init : ()->
			self = @
			# check last opened workspace 
			if localStorage['last_opened_workspace'] and (localStorage['last_opened_workspace'] isnt Nimbus.realtime.c_file.id)
				@open(
					id : localStorage['last_opened_workspace']
				)
			else
				localStorage['last_opened_workspace'] = Nimbus.realtime.c_file.id
				foundry.shared_users((users)->
					_users = users
					foundry.current_user((me)->
						for user in _users
							if user.id is me.id
								foundry._current_user.role = user.role

						# check user email
						if !foundry._current_user.email
							foundry._current_user.email = Nimbus.Share.get_user_email()
						
						console.log _users
						foundry.initialized('workspaces')
					)
				)

			# use controller
			define_controller()
		inited : ()->
			log 'inited'
			if @switch_callback
				@switch_callback()

			# test analytic api 
			console.log analytic
		# switch callback is for 
		# switching document finished, and inited is called
		switch_callback : null
		# get all workspaces
		# this is identical to Nimbus.realtime.app_files for now
		all_doc : ()->
			# filter folder
			@_app_files = Nimbus.realtime.app_files
			@_app_files

		# open a workspace 
		# @input - document object
		# @callback - will be called when the document is loaded
		open : (doc, callback)->
			# open file
			localStorage['last_opened_workspace'] = doc.id
			Nimbus.Share.switch_to_app_file_real(doc.id, ()->
				# foundry.reinitialize()
				callback() if callback
				angular.element(document).scope().$apply()

				# setup analytics parameters
				ga('set', 'dimension2', Nimbus.realtime.c_file.title);
				ga('set', 'dimension3', Nimbus.realtime.c_file.owners[0].emailAddress+':'+Nimbus.realtime.c_file.owners[0].displayName);
				ga('set', 'dimension4', foundry._models.User.all())
				return
			)
			return

		# create a workspace with 
		# @input - name of the space
		# @callback - after the worksapce is created and callback with document data
		create : (name, callback)->
			# exception on null name
			if !name
				console.log 'name required'
			self = @
			Nimbus.Share.create_workspace(name, (data)->
				callback(data) if callback
				angular.element(document).scope().$apply()
				return
			)

			# add analytic event
			analytic.owner(
				id : foundry._current_user.id
				email : foundry._current_user.email
				date : new Date().getTime()
				'name' : name
			)

			return

		current : ()->
			# return current opened file
			return Nimbus.realtime.c_file

		is_current : (doc)->
			return doc.id is Nimbus.realtime.c_file.id

		# going to implement this in google drive
		rename : (doc, name, cb)->
			self = @
			id = doc.id
			old_name = doc.title
			param = 
				path: "/drive/v2/files/"+id
				method: "PATCH"
				params: 
					key: Nimbus.Auth.key
					fileId : id
				body:
					title : name	
				callback:(file)->
					for index,_file of Nimbus.realtime.app_files
						if doc.id is _file.id
							file.title = name	
					# the folder belongs to the current space
					folder = Nimbus.realtime.folder.binary_files

					# apply changes 
					apply_changes = (changed_file)->
						if cb
							cb(changed_file)
						angular.element(document).scope().$apply()

					# rename folder and determine whether to replace 
					rename_folder = (target, replace)->
						self.rename_folder(target, name+' files', (f)->
							if replace
								window.folder.binary_files = f
							apply_changes(file)
						)
					if c_file.id isnt id
						# get the folder first
					    query = "mimeType = 'application/vnd.google-apps.folder' and title = '" + old_name + " files' and properties has { key='space' and value='" + id + "' and visibility='PRIVATE' }";
					    Nimbus.Client.GDrive.getMetadataList(query, (data)->
					    	if !data.error 
					    		if data.items.length >=  1
						    		folder = data.items[0]
						    		rename_folder(folder)
						    	else
						    		apply_changes()
						    else
						    	apply_changes()
					    )
					else
						rename_folder(folder, true)
					
					return
			
			request = gapi.client.request(param)
			# request.execute()
			return
		# input folder object
		# and the name to be changed
		# callback
		rename_folder : (folder, name, cb)->
			log 'rename the folder'
			id = folder.id
			param = 
				path: "/drive/v2/files/"+id
				method: "PATCH"
				params: 
					key: Nimbus.Auth.key
					fileId : id
				body:
					title : name	
				callback:(file)->
					if cb
						cb(file)

					angular.element(document).scope().$apply()

			request = gapi.client.request(param)
			# request.execute()
			return
		del_doc : (doc, callback)->
			# delte document
			return if doc.id is Nimbus.realtime.c_file.id
			Nimbus.Share.deleteFile(doc.id) if Nimbus.Share.deleteFile
			@_app_files = Nimbus.realtime.app_files

			callback() if callback

			return
				
)

define_controller = ()->

	angular.module('foundry').controller('ProjectController', ['$scope', '$rootScope', 'ngDialog', '$foundry', ($scope, $rootScope, ngDialog, $foundry)->
		docModule = foundry.load('workspaces')

		$rootScope.breadcum = 'Workspace'
		$scope.filename = ''
		$scope.current_edit = -1

		$scope.load = ()->
			$scope.projects = docModule.all_doc()

		$scope.is_loaded = (doc)->
			docModule.is_current(doc)

		$scope.add_document = ()->
			$scope.filename = ''
			# open modal
			ngDialog.open
				template: 'newfile'
				controller : @
				scope: $scope
			return

		$scope.create_doc = ()->
			# retrive file name
			ngDialog.close()
		
			spinner = $foundry.spinner(
				type : 'loading'
				text : 'Creating '+$scope.filename+'...'
			)
			docModule.create($scope.filename, (file)->
				if file.title is $scope.filename
					$scope.load()
					# ngDialog.close()
					spinner.hide()

					# switch to that doc
					for index,project of $scope.projects
						if file.id is project.id
							$scope.switch(index)
							return	
				
			)
			return

		$scope.edit = (index)->
			doc = $scope.projects[index]
			$scope.current_edit = index
			$scope.newname = doc.title
			ngDialog.open
				template: 'rename'
				scope: $scope
			return

		$scope.switch = (index)->
			$scope.current_doc = doc = $scope.projects[index]
			
			spinner = $foundry.spinner(
				type : 'loading'
				text : 'Switching...'
			)
			
			docModule.open(doc,()->
				$scope.load()
				spinner.hide()
			)
			return

		$scope.rename = ()->
			doc = $scope.projects[$scope.current_edit]
			spinner = $foundry.spinner(
				type : 'loading'
				text : 'Renaming...'
			)
			ngDialog.close()

			docModule.rename(doc, $scope.newname, (file)->
				console.log file
				$scope.load()
				spinner.hide()
			)
			return

		$scope.delet_doc = (index)->
			doc = $scope.projects[index]
			docModule.del_doc(doc)
			return

		$scope.load()

		return
	])

	# add template cache
	angular.module('foundry').run(['$templateCache', ($templateCache)->
		html = '<div ng-controller="ProjectController">
			    <div class="breadcrumb">
			        <h1 ng-bind="breadcum"></h1>
			        <div class="pull-right">
			            <a class="btn outline" ng-click="add_document()">Add Workspace</a>
			        </div>  
			    </div>          
			    <div class="container-fluid">
			        <div class="row-fluid">
			            <div class="well-content">
			                <table class="table">
			                    <thead>
			                        <tr>
			                            <th>Current Workspaces</th>
			                        </tr>
			                    </thead>
			                    <tbody>
			                        <tr ng-repeat="project in projects">
			                            <td>
			                                <div class="user_listing">
			                                    <i class="icon-folder-open colored-icon" ></i>
			                                    <span class="name">{{project.title}}</span>
			                                    <span class="pill" ng-show="is_loaded(project)">Loaded</span>
			                                    <div class="pull-right list_menu">
			                                        <a class="btn outline narrow" ng-click="switch($index)">switch</a>
			                                        <a class="btn outline narrow" ng-click="edit($index)">edit</a>
			                                        <a class="btn outline narrow" confirm on-confirm="delet_doc($index)" ng-hide="is_loaded(project)"><i class="icon-trash" ></i></a>
			                                    </div>
			                                </div>
			                            </td>
			                        </tr>
			                    </tbody>
			                </table>
			            </div>
			        </div>
			        <script type="text/ng-template" id="newfile">
			            <div class="nimbus_form_modal">
			                <div class="modal-dialog">
			                    <div class="modal-content">
			                      <div class="modal-header">
			                        <h4 class="modal-title">Add Document</h4>
			                      </div>
			                      <div class="modal-body">
			                        <form method="get" accept-charset="utf-8">
			                            <div class="nimb_form input" style="height:70px;">
			                                <label>Name</label>
			                                <input type="text" ng-model="filename" placeholder="Type in document name" style="height:30px;margin-top:0px">
			                            </div>
			                        </form>
			                        <button type="button" class="btn btn-primary" ng-click="create_doc()">Create</button>
			                      </div>
			                    </div><!-- /.modal-content -->
			                </div><!-- /.modal-dialog -->
			            </div>
			        </script>
			        <script type="text/ng-template" id="rename">
			            <div class="nimbus_form_modal">
			                <div class="modal-dialog">
			                    <div class="modal-content">
			                      <div class="modal-header">
			                        <h4 class="modal-title">Rename Document</h4>
			                      </div>
			                      <div class="modal-body">
			                        <form method="get" accept-charset="utf-8">
			                            <div class="nimb_form input" style="height:70px;">
			                                <label>Name</label>
			                                <input type="text" ng-model="newname" placeholder="Type in document name" style="height:30px;margin-top:0px">
			                            </div>
			                        </form>
			                        <button type="button" class="btn btn-primary" ng-click="rename()">Rename</button>
			                      </div>
			                    </div><!-- /.modal-content -->
			                </div><!-- /.modal-dialog -->
			            </div>
			        </script>
			        <script type="text/ng-template" id="swithing">
			            <div class="title"> swtiching to <span class="label label-success">{{current_doc.title}}</span>...</div>
			        </script>
			    </div>
			</div>'
		$templateCache.put('app/plugins/workspaces/index.html', html)
	])

