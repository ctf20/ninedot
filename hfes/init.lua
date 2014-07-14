require 'torch'
hfes = {}

torch.include('hfes','EClassifier.lua')
torch.include('hfes','ClassifierModule.lua')
torch.include('hfes','GridClassifier.lua')
torch.include('hfes','LineClassifier.lua')
torch.include('hfes','LineClassifierTwo.lua')
torch.include('hfes','PointClassifier.lua')
torch.include('hfes','PointClassifierTwo.lua')
torch.include('hfes','Classifier.lua')
torch.include('hfes','NineDotClassifier.lua')
torch.include('hfes','hFES.lua')
torch.include('hfes','ninedot.lua')
torch.include('hfes','util.lua')

return hfes
