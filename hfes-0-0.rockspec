package = 'hfes'
version = '0-0'

source = {
	url = '',
	branch = 'visualization4'
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
		['hfes.hFES'] = 'hfes/hFES.lua',
		['hfes.ninedot'] = 'hfes/ninedot.lua',
		['hfes.util'] = 'hfes/util.lua',
		['hfes.Classifier'] = 'hfes/Classifier.lua',
		['hfes.NineDotClassifier'] = 'hfes/NineDotClassifier.lua',
		['hfes.ClassifierModule'] = 'hfes/ClassifierModule.lua',
		['hfes.GridClassifier'] = 'hfes/GridClassifier.lua',
		['hfes.LineClassifier'] = 'hfes/LineClassifier.lua',
		['hfes.LineClassifierTwo'] = 'hfes/LineClassifierTwo.lua',
		['hfes.PointClassifier'] = 'hfes/PointClassifier.lua',
    }
}