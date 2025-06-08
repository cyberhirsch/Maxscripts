try ( destroyDialog rOverSizeRender ) catch()

if ( rOversizeRender_BaseX == undefined ) then /* persistent */ global rOversizeRender_BaseX = undefined
if ( rOversizeRender_BaseY == undefined ) then /* persistent */ global rOversizeRender_BaseY = undefined
if ( rOversizeRender_BaseFov == undefined ) then /* persistent */ global rOversizeRender_BaseFov = undefined
if ( rOversizeRender_BaseFl == undefined ) then /* persistent */ global rOversizeRender_BaseFl = undefined
if ( rOversizeRender_UsePixAspect == undefined ) then /* persistent */ global rOversizeRender_UsePixAspect = false
if ( rOversizeRender_BakeNewCameras == undefined ) then /* persistent */ global rOversizeRender_BakeNewCameras = true
if ( rOversizeRender_oversize == undefined ) then /* persistent */ global rOversizeRender_oversize = 0
if ( rOversizeRender_oversizeMode == undefined ) then /* persistent */ global rOversizeRender_oversizeMode = 1
if ( rOversizeRender_oversizePercent == undefined ) then /* persistent */ global rOversizeRender_oversizePercent = 10.0
if ( rOversizeRender_oversizeX == undefined ) then /* persistent */ global rOversizeRender_oversizeX = 100
if ( rOversizeRender_oversizeY == undefined ) then /* persistent */ global rOversizeRender_oversizeY = 100
if ( rOversizeRender_finalResX == undefined ) then /* persistent */ global rOversizeRender_finalResX = 1920
if ( rOversizeRender_finalResY == undefined ) then /* persistent */ global rOversizeRender_finalResY = 1080
if ( rOversizeRender_selectedCamera == undefined ) then /* persistent */ global rOversizeRender_selectedCamera = undefined

-- Define the filter function globally before the rollout
function superclassof_test obj = (superclassof obj == Camera)

rollout rOverSizeRender "OversizeRender" width:170 height:430
(
	groupBox grp1 "Source Camera" pos:[2,2] width:166 height:60
	pickbutton btnPickCamera "Pick Source Camera" pos:[8,20] width:108 height:20 filter:superclassof_test tooltip:"Select the source camera to work with"
	button btnRefreshCam "Refresh" pos:[118,20] width:45 height:20 tooltip:"Refresh camera information from selected camera"
	label lblSelectedCam "" pos:[8,42] width:150 height:16
	
	groupBox grp2 "Base Resolution" pos:[2,65] width:166 height:112
	spinner spnBaseX "ResX : " pos:[20,88] width:96 height:16 range:[0,20000,0] type:#integer scale:1
	spinner spnBaseY "ResY : " pos:[20,106] width:96 height:16 range:[0,20000,0] type:#integer scale:1
	spinner spnBaseFov "FOV : " pos:[20,124] width:96 height:16 range:[0.1,175,45]
	button btnUseCurrent "use Current" pos:[23,149] width:80 height:20 tooltip:"Use current render settings and camera FOV/focal length"

	checkBox chkBakeNewCameras "bake new cameras" pos:[13,182] width:200 height:16 tooltip:"Create new cameras instead of modifying existing ones"
	checkBox chkUsePixAspect "use pixelaspect" pos:[13,200] width:200 height:16 tooltip:"Take pixel aspect ratio into account for calculations"
	
	groupBox grp3 "Oversize Method" pos:[2,218] width:166 height:130
	radioButtons rdoOversizeMode labels:#("Uniform Pixels", "Percentage", "Separate Pixels", "Final Resolution") columns:1 pos:[10,236] default:1
	
	-- Controls for different modes
	spinner spnOverSize "Pixels : " pos:[13,298] width:105 height:16 range:[-10000,10000,0] type:#integer scale:1
	spinner spnOversizePercent "Percent : " pos:[13,298] width:105 height:16 range:[0,1000,10] visible:false
	
	label lblSepX "X Pixels :" pos:[13,298] visible:false
	spinner spnOversizeX "" pos:[65,298] width:70 height:16 range:[-10000,10000,100] type:#integer scale:1 visible:false
	label lblSepY "Y Pixels :" pos:[13,318] visible:false  
	spinner spnOversizeY "" pos:[65,318] width:70 height:16 range:[-10000,10000,100] type:#integer scale:1 visible:false
	
	label lblFinalX "Final X :" pos:[13,298] visible:false
	spinner spnFinalResX "" pos:[65,298] width:70 height:16 range:[1,20000,1920] type:#integer scale:1 visible:false
	label lblFinalY "Final Y :" pos:[13,318] visible:false
	spinner spnFinalResY "" pos:[65,318] width:70 height:16 range:[1,20000,1080] type:#integer scale:1 visible:false
	
	groupBox grp4 "Actions" pos:[2,353] width:166 height:70
	button btnUseBase "use Base" pos:[8,371] width:50 height:20 tooltip:"Apply base resolution and FOV to current scene"
	button btnUseOversized "use Oversized" pos:[62,371] width:70 height:20 tooltip:"Apply oversized resolution and adjusted FOV to current scene"
	button btnCreateCameras "Create Cameras" pos:[8,396] width:75 height:20 tooltip:"Create new base and oversized cameras with baked animation"
	button btnLoadFromCam "Load from Cam" pos:[87,396] width:75 height:20 tooltip:"Load oversize settings from selected camera's user properties"
	
	local cam = undefined
	local sourceCam = undefined
	
	function updateCameraLabel = 
	(
		if sourceCam != undefined and isValidNode sourceCam then
			lblSelectedCam.text = sourceCam.name
		else
			lblSelectedCam.text = "None selected"
	)
	
	function updateOversizeControls = 
	(
		-- Hide all controls first
		spnOverSize.visible = false
		spnOversizePercent.visible = false
		lblSepX.visible = false
		spnOversizeX.visible = false
		lblSepY.visible = false
		spnOversizeY.visible = false
		lblFinalX.visible = false
		spnFinalResX.visible = false
		lblFinalY.visible = false
		spnFinalResY.visible = false
		
		-- Show appropriate controls based on mode
		case rdoOversizeMode.state of
		(
			1: spnOverSize.visible = true  -- Uniform Pixels
			2: spnOversizePercent.visible = true  -- Percentage
			3: (  -- Separate Pixels
				lblSepX.visible = true
				spnOversizeX.visible = true
				lblSepY.visible = true
				spnOversizeY.visible = true
			)
			4: (  -- Final Resolution
				lblFinalX.visible = true
				spnFinalResX.visible = true
				lblFinalY.visible = true
				spnFinalResY.visible = true
			)
		)
	)
	
	function calculateOversizedDimensions = 
	(
		local newWidth = rOversizeRender_BaseX
		local newHeight = rOversizeRender_BaseY
		
		case rdoOversizeMode.state of
		(
			1: (  -- Uniform Pixels
				newWidth = rOversizeRender_BaseX + spnOverSize.value * 2
				if ( rOversizeRender_UsePixAspect ) then 
					newHeight = rOversizeRender_BaseY + spnOverSize.value * renderPixelAspect * 2
				else 
					newHeight = rOversizeRender_BaseY + spnOverSize.value * 2
			)
			2: (  -- Percentage
				local factor = 1.0 + (spnOversizePercent.value / 100.0)
				newWidth = (rOversizeRender_BaseX * factor) as integer
				if ( rOversizeRender_UsePixAspect ) then 
					newHeight = (rOversizeRender_BaseY * factor * renderPixelAspect) as integer
				else 
					newHeight = (rOversizeRender_BaseY * factor) as integer
			)
			3: (  -- Separate Pixels
				newWidth = rOversizeRender_BaseX + spnOversizeX.value * 2
				if ( rOversizeRender_UsePixAspect ) then 
					newHeight = rOversizeRender_BaseY + spnOversizeY.value * renderPixelAspect * 2
				else 
					newHeight = rOversizeRender_BaseY + spnOversizeY.value * 2
			)
			4: (  -- Final Resolution
				newWidth = spnFinalResX.value
				newHeight = spnFinalResY.value
			)
		)
		
		#(newWidth, newHeight)
	)
	
	function bakeCameraAnimation sourceCam targetCam = 
	(
		-- Create temporary helper for baking
		local bakeHelper = dummy name:"bakehelp"
		
		-- Set up constraints on helper
		local pc = position_constraint()
		bakeHelper.position.controller = pc
		pc.appendTarget sourceCam 100.0 
		
		local rc = Orientation_constraint()
		bakeHelper.rotation.controller = rc
		rc.appendTarget sourceCam 100.0
		
		-- Bake animation from source to helper
		for t = animationrange.start to animationrange.end do
		(
			with animate on
			(
				at time t trans = sourceCam.transform
				at time t bakeHelper.transform = trans
				max set key keys
			)
		)
		
		-- Set target camera controllers to basic types
		targetCam.pos.controller = Position_XYZ()
		targetCam.rotation.controller = Euler_XYZ()
		
		-- Transfer animation from helper to target camera
		for t = animationRange.start to animationrange.end do
		(
			with animate on
			(
				at time t transre = bakeHelper.transform
				at time t targetCam.transform = transre
				max set key keys
			)
		)
		
		-- Set interpolation to linear
		setBeforeORT targetCam.pos.controller #linear
		setBeforeORT targetCam.rotation.controller #linear
		setBeforeORT targetCam.scale.controller #linear
		setAfterORT targetCam.pos.controller #linear
		setAfterORT targetCam.rotation.controller #linear
		setAfterORT targetCam.scale.controller #linear
		
		-- Clean up helper
		delete bakeHelper
	)
	
	function saveDataToCameraProperties cam baseResX baseResY baseFOV baseFocalLength oversizeData = 
	(
		setUserProp cam "OversizeRender_BaseResX" baseResX
		setUserProp cam "OversizeRender_BaseResY" baseResY
		setUserProp cam "OversizeRender_BaseFOV" baseFOV
		if baseFocalLength != undefined then
			setUserProp cam "OversizeRender_BaseFocalLength" baseFocalLength
		setUserProp cam "OversizeRender_OversizeMode" rdoOversizeMode.state
		setUserProp cam "OversizeRender_UsePixAspect" rOversizeRender_UsePixAspect
		setUserProp cam "OversizeRender_BakeNewCameras" rOversizeRender_BakeNewCameras
		
		case rdoOversizeMode.state of
		(
			1: setUserProp cam "OversizeRender_OversizePixels" spnOverSize.value
			2: setUserProp cam "OversizeRender_OversizePercent" spnOversizePercent.value
			3: (
				setUserProp cam "OversizeRender_OversizeX" spnOversizeX.value
				setUserProp cam "OversizeRender_OversizeY" spnOversizeY.value
			)
			4: (
				setUserProp cam "OversizeRender_FinalResX" spnFinalResX.value
				setUserProp cam "OversizeRender_FinalResY" spnFinalResY.value
			)
		)
	)
	
	function loadDataFromCameraProperties cam = 
	(
		local baseResX = getUserProp cam "OversizeRender_BaseResX"
		local baseResY = getUserProp cam "OversizeRender_BaseResY"
		local baseFOV = getUserProp cam "OversizeRender_BaseFOV"
		local baseFocalLength = getUserProp cam "OversizeRender_BaseFocalLength"
		local oversizeMode = getUserProp cam "OversizeRender_OversizeMode"
		local usePixAspect = getUserProp cam "OversizeRender_UsePixAspect"
		local bakeNewCameras = getUserProp cam "OversizeRender_BakeNewCameras"
		
		if baseResX != undefined then (
			rOversizeRender_BaseX = baseResX
			spnBaseX.value = baseResX
		)
		if baseResY != undefined then (
			rOversizeRender_BaseY = baseResY
			spnBaseY.value = baseResY
		)
		if baseFOV != undefined then (
			rOversizeRender_BaseFov = baseFOV
			spnBaseFov.value = baseFOV
		)
		if baseFocalLength != undefined then (
			rOversizeRender_BaseFl = baseFocalLength
		)
		if oversizeMode != undefined then (
			rdoOversizeMode.state = oversizeMode
			rOversizeRender_oversizeMode = oversizeMode
		)
		if usePixAspect != undefined then (
			chkUsePixAspect.state = usePixAspect
			rOversizeRender_UsePixAspect = usePixAspect
		)
		if bakeNewCameras != undefined then (
			chkBakeNewCameras.state = bakeNewCameras
			rOversizeRender_BakeNewCameras = bakeNewCameras
		)
		
		-- Load oversize values based on mode
		case oversizeMode of
		(
			1: (
				local oversizePixels = getUserProp cam "OversizeRender_OversizePixels"
				if oversizePixels != undefined then (
					spnOverSize.value = oversizePixels
					rOversizeRender_oversize = oversizePixels
				)
			)
			2: (
				local oversizePercent = getUserProp cam "OversizeRender_OversizePercent"
				if oversizePercent != undefined then (
					spnOversizePercent.value = oversizePercent
					rOversizeRender_oversizePercent = oversizePercent
				)
			)
			3: (
				local oversizeX = getUserProp cam "OversizeRender_OversizeX"
				local oversizeY = getUserProp cam "OversizeRender_OversizeY"
				if oversizeX != undefined then (
					spnOversizeX.value = oversizeX
					rOversizeRender_oversizeX = oversizeX
				)
				if oversizeY != undefined then (
					spnOversizeY.value = oversizeY
					rOversizeRender_oversizeY = oversizeY
				)
			)
			4: (
				local finalResX = getUserProp cam "OversizeRender_FinalResX"
				local finalResY = getUserProp cam "OversizeRender_FinalResY"
				if finalResX != undefined then (
					spnFinalResX.value = finalResX
					rOversizeRender_finalResX = finalResX
				)
				if finalResY != undefined then (
					spnFinalResY.value = finalResY
					rOversizeRender_finalResY = finalResY
				)
			)
		)
		
		updateOversizeControls()
	)
	
	on rOversizeRender open do
	(
		cam = viewport.getCamera()
		if rOversizeRender_selectedCamera != undefined and isValidNode rOversizeRender_selectedCamera then
			sourceCam = rOversizeRender_selectedCamera
		else if cam != undefined then
			sourceCam = cam
			
		updateCameraLabel()
		
		if ( sourceCam == undefined ) then
		(
			MessageBox "Please pick a source camera first" caption:"Info"
			grp2.enabled = false
			grp3.enabled = false
			grp4.enabled = false
		)
		else
		(
			if ( rOversizeRender_BaseX == undefined ) then /* persistent */ global rOversizeRender_BaseX = renderWidth
			if ( rOversizeRender_BaseY == undefined ) then /* persistent */ global rOversizeRender_BaseY = renderHeight
			
			if classOf sourceCam == VRayPhysicalCamera then (
				if ( rOversizeRender_BaseFl == undefined ) then /* persistent */ global rOversizeRender_BaseFl = sourceCam.focal_length
				spnBaseFov.text = "FL : "
				spnBaseFov.value = rOversizeRender_BaseFl
			) else (
				if ( rOversizeRender_BaseFov == undefined ) then /* persistent */ global rOversizeRender_BaseFov = sourceCam.fov
				spnBaseFov.text = "FOV : "
				spnBaseFov.value = rOversizeRender_BaseFov
			)
			
			if ( rOversizeRender_UsePixAspect == undefined ) then /* persistent */ global rOversizeRender_UsePixAspect = false;
			if ( rOversizeRender_BakeNewCameras == undefined ) then /* persistent */ global rOversizeRender_BakeNewCameras = true;
			spnBaseX.value = rOversizeRender_BaseX
			spnBaseY.value = rOversizeRender_BaseY
			
			chkUsePixAspect.state = rOversizeRender_UsePixAspect
			chkBakeNewCameras.state = rOversizeRender_BakeNewCameras
			
			-- Set control values
			rdoOversizeMode.state = rOversizeRender_oversizeMode
			spnOverSize.value = rOversizeRender_oversize
			spnOversizePercent.value = rOversizeRender_oversizePercent
			spnOversizeX.value = rOversizeRender_oversizeX
			spnOversizeY.value = rOversizeRender_oversizeY
			spnFinalResX.value = rOversizeRender_finalResX
			spnFinalResY.value = rOversizeRender_finalResY
			
			updateOversizeControls()
		)
	)
	
	on btnPickCamera picked obj do
	(
		sourceCam = obj
		rOversizeRender_selectedCamera = obj
		updateCameraLabel()
		
		-- Enable UI elements
		grp2.enabled = true
		grp3.enabled = true
		grp4.enabled = true
		
		-- Update FOV display based on camera type
		if classOf sourceCam == VRayPhysicalCamera then (
			spnBaseFov.text = "FL : "
			spnBaseFov.value = sourceCam.focal_length
			rOversizeRender_BaseFl = sourceCam.focal_length
		) else (
			spnBaseFov.text = "FOV : "
			spnBaseFov.value = sourceCam.fov
			rOversizeRender_BaseFov = sourceCam.fov
		)
	)
	
	on btnRefreshCam pressed do
	(
		updateCameraLabel()
		if sourceCam != undefined and isValidNode sourceCam then (
			-- Update FOV/FL from current camera
			if classOf sourceCam == VRayPhysicalCamera then (
				rOversizeRender_BaseFl = sourceCam.focal_length
				spnBaseFov.value = rOversizeRender_BaseFl
			) else (
				rOversizeRender_BaseFov = sourceCam.fov
				spnBaseFov.value = rOversizeRender_BaseFov
			)
		)
	)
	
	on rdoOversizeMode changed state do 
	(
		rOversizeRender_oversizeMode = state
		updateOversizeControls()
	)
	
	on spnBaseX changed val do rOversizeRender_BaseX = val
	on spnBaseY changed val do rOversizeRender_BaseY = val
	on spnBaseFov changed val do 
	(
		if classOf sourceCam == VRayPhysicalCamera then
			rOversizeRender_BaseFl = val
		else
			rOversizeRender_BaseFov = val
	)
	on chkUsePixAspect changed val do rOversizeRender_UsePixAspect = val
	on chkBakeNewCameras changed val do rOversizeRender_BakeNewCameras = val
	on spnOverSize changed val do rOversizeRender_oversize = val
	on spnOversizePercent changed val do rOversizeRender_oversizePercent = val
	on spnOversizeX changed val do rOversizeRender_oversizeX = val
	on spnOversizeY changed val do rOversizeRender_oversizeY = val
	on spnFinalResX changed val do rOversizeRender_finalResX = val
	on spnFinalResY changed val do rOversizeRender_finalResY = val
		
	on btnUseCurrent pressed do
	(	
		if sourceCam != undefined then (
			if classOf sourceCam == VRayPhysicalCamera then  
				rOversizeRender_BaseFl = sourceCam.focal_length
			else 
				rOversizeRender_BaseFov = sourceCam.fov
				
			spnBaseFov.value = if classOf sourceCam == VRayPhysicalCamera then rOversizeRender_BaseFl else rOversizeRender_BaseFov
			rOversizeRender_BaseX = renderWidth
			spnBaseX.value = rOversizeRender_BaseX
			rOversizeRender_BaseY = renderHeight
			spnBaseY.value = rOversizeRender_BaseY
		)
	)
	
	on btnUseBase pressed do
	(
		if sourceCam == undefined then (
			MessageBox "Please pick a source camera first" caption:"Error"
			return()
		)
		
		local wasOpen = renderSceneDialog.isOpen()
		renderSceneDialog.close() 
		
		renderWidth  = rOversizeRender_BaseX
		renderHeight = rOversizeRender_BaseY
		
		if classOf sourceCam == VRayPhysicalCamera then  
			sourceCam.focal_length = rOversizeRender_BaseFl
		else 
			sourceCam.fov = rOversizeRender_BaseFov
		
		renderSceneDialog.update()
		if ( wasOpen == true ) then renderSceneDialog.open ()
	)
	
	on btnUseOversized pressed do
	(
		if sourceCam == undefined then (
			MessageBox "Please pick a source camera first" caption:"Error"
			return()
		)
		
		local wasOpen = renderSceneDialog.isOpen()
		renderSceneDialog.close() 
		
		local newDimensions = calculateOversizedDimensions()
		renderWidth = newDimensions[1]
		renderHeight = newDimensions[2]
		
		-- Calculate new FOV
		local stopMe = false
		local baseFov = rOversizeRender_BaseFov
		
		if classOf sourceCam == VRayPhysicalCamera then (
			if sourceCam.film_width != getRendApertureWidth() then (
				messagebox "Can't work with selected cam: camera's film width and the scene's render aperture width don't match."
				stopMe = true
			) else baseFov = 2.0 * atan (sourceCam.film_width / (2.0 * rOversizeRender_BaseFl))
		)
		
		if not(stopMe) then (
			alpha = baseFov / 2.0
			virtDist = rOversizeRender_BaseX*.5 / sin alpha * cos alpha
			c = length [ renderWidth * .5, virtDist ]
			alphaNeu = asin ( ( renderWidth * .5 ) / c )
			fovNew = (alphaNeu * 2)
			
			if classOf sourceCam == VRayPhysicalCamera then ( 
				sourceCam.focal_length = (cameraFOV.FOVtoMM fovNew)
			) else (
				sourceCam.fov = fovNew
			)
		)
		renderSceneDialog.update()
		if ( wasOpen == true ) then renderSceneDialog.open ()
	)
	
	on btnCreateCameras pressed do
	(
		if sourceCam == undefined then (
			MessageBox "Please pick a source camera first" caption:"Error"
			return()
		)
		
		-- Use the source camera name as base name
		local baseName = sourceCam.name
		
		-- Create base camera
		local baseCamName = baseName + "_base"
		local baseCam = undefined
		
		if classOf sourceCam == VRayPhysicalCamera then
			baseCam = VRayPhysicalCamera name:baseCamName
		else
			baseCam = freecamera name:baseCamName
		
		-- Set base camera properties
		if classOf baseCam == VRayPhysicalCamera then
			baseCam.focal_length = rOversizeRender_BaseFl
		else
			baseCam.fov = rOversizeRender_BaseFov
		
		-- Bake animation to base camera if option is enabled
		if rOversizeRender_BakeNewCameras then
			bakeCameraAnimation sourceCam baseCam
		
		-- Save data to base camera properties
		saveDataToCameraProperties baseCam rOversizeRender_BaseX rOversizeRender_BaseY rOversizeRender_BaseFov rOversizeRender_BaseFl ""
		
		-- Create oversized camera
		local oversizeCamName = baseName + "_oversize"
		local oversizeCam = undefined
		
		if classOf sourceCam == VRayPhysicalCamera then
			oversizeCam = VRayPhysicalCamera name:oversizeCamName
		else
			oversizeCam = freecamera name:oversizeCamName
		
		-- Calculate oversized dimensions and FOV
		local newDimensions = calculateOversizedDimensions()
		local stopMe = false
		local baseFov = rOversizeRender_BaseFov
		local newFocalLength = rOversizeRender_BaseFl
		
		if classOf sourceCam == VRayPhysicalCamera then (
			if sourceCam.film_width != getRendApertureWidth() then (
				messagebox "Can't work with selected cam: camera's film width and the scene's render aperture width don't match."
				stopMe = true
			) else baseFov = 2.0 * atan (sourceCam.film_width / (2.0 * rOversizeRender_BaseFl))
		)
		
		if not(stopMe) then (
			alpha = baseFov / 2.0
			virtDist = rOversizeRender_BaseX*.5 / sin alpha * cos alpha
			c = length [ newDimensions[1] * .5, virtDist ]
			alphaNeu = asin ( ( newDimensions[1] * .5 ) / c )
			fovNew = (alphaNeu * 2)
			
			if classOf sourceCam == VRayPhysicalCamera then 
				newFocalLength = (cameraFOV.FOVtoMM fovNew)
			else
				baseFov = fovNew
		)
		
		-- Set oversized camera properties
		if classOf oversizeCam == VRayPhysicalCamera then
			oversizeCam.focal_length = newFocalLength
		else
			oversizeCam.fov = baseFov
		
		-- Bake animation to oversized camera if option is enabled
		if rOversizeRender_BakeNewCameras then
			bakeCameraAnimation sourceCam oversizeCam
		
		-- Save data to oversized camera properties
		saveDataToCameraProperties oversizeCam rOversizeRender_BaseX rOversizeRender_BaseY rOversizeRender_BaseFov rOversizeRender_BaseFl ""
		setUserProp oversizeCam "OversizeRender_OversizedWidth" newDimensions[1]
		setUserProp oversizeCam "OversizeRender_OversizedHeight" newDimensions[2]
		setUserProp oversizeCam "OversizeRender_OversizedFOV" baseFov
		if classOf oversizeCam == VRayPhysicalCamera then
			setUserProp oversizeCam "OversizeRender_OversizedFocalLength" newFocalLength
		
		MessageBox ("Created cameras:\n" + baseCamName + "\n" + oversizeCamName) title:"Success"
	)
	
	on btnLoadFromCam pressed do
	(
		if sourceCam == undefined then (
			MessageBox "Please pick a source camera first" caption:"Error"
			return()
		)
		
		-- Check if camera has oversize render data
		local hasData = getUserProp sourceCam "OversizeRender_BaseResX"
		if hasData == undefined then (
			MessageBox "Selected camera doesn't contain OversizeRender data" caption:"Error"
			return()
		)
		
		loadDataFromCameraProperties sourceCam
		MessageBox "Data loaded from camera properties" title:"Success"
	)
)

createDialog rOverSizeRender
