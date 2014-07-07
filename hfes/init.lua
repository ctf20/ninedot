require 'torch'
hfes = {}

torch.include('hfes','hFES.lua')
torch.include('hfes','Classifier.lua')
torch.include('hfes','GridClassifier.lua')
torch.include('hfes','LineClassifier.lua')
torch.include('hfes','PointClassifier.lua')
torch.include('hfes','ninedot.lua')
torch.include('hfes','util.lua')

return hfes
