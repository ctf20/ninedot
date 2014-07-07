package = 'hfes'
version = '0-0'

source = {
	url = '',
	branch = 'master'
}


description = {
	summary = 'Hierarchical Feature Evolution System package',
	homepage = '',
}

dependencies = {'torch >= 7.0'}
build = {
	type = 'builtin',
	modules = {
		['hfes.init'] = 'hfes/init.lua',
		['hfes.ninedot'] = 'hfes/ninedot.lua',
		['hfes.hFES'] = 'hfes/hFES.lua',
<<<<<<< HEAD
		['hfes.util'] = 'hfes/util.lua',		
=======
		['hfes.Classifier'] = 'hfes/Classifier.lua',
		['hfes.GridClassifier'] = 'hfes/GridClassifier.lua',
		['hfes.PointClassifier'] = 'hfes/PointClassifier.lua',
>>>>>>> alex_matching
    }
}