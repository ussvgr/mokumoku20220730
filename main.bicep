targetScope = 'resourceGroup'

// references
@description('Application name')
param appName string = 'mokumoku20220730'
param location string = resourceGroup().location

param randomStr string

// VM Settings
@secure()
param sshPublicKey string
var virtualMachineName = '${appName}-vm'

// AKS Settings
param agentCount int = 1
param agentVMSize string = 'Standard_ds2_v2'
var clusterName = '${appName}-aks'
var PrivateCluster = true

// DB Settings
param administratorLogin string = 'spring'
param administratorLoginPassword string = 'ThisIsTest#123'
var databaseName = '${appName}-db-${randomStr}'

// ACR Settings
var acrName = '${appName}acr${randomStr}'

module vnet 'modules/network.bicep' = {
  name: 'Vnet-deploy'
  params: {
    virtualNetworkName: 'Vnet'
    location: location
    addressPrefix: '192.168.0.0/16'
    AKSsubnetName: 'AksSubnet'
    AKSsubnetPrefix: '192.168.0.0/24'
    DBsubnetName: 'DbSubnet'
    DBsubnetPrefix: '192.168.1.0/24'
    ACRsubnetName: 'AcrSubnet'
    ACRsubnetPrefix: '192.168.2.0/24'
    KVsubnetName: 'KvSubnet'
    KVsubnetPrefix: '192.168.3.0/24'
    VMsubnetName: 'VMSubnet'
    VMsubnetPrefix: '192.168.254.0/24'
  }
}

module vm 'modules/linux-vm.bicep' = {
  name: '${virtualMachineName}-deploy'
  params: {
    virtualMachineName: '${appName}-vm'
    location: location
    virtualNetworkName: 'Vnet'
    subnetName: 'VMSubnet'
    sshPublicKey: sshPublicKey
  }
  dependsOn: [
    vnet
  ]
}

module aks 'modules/aks.bicep' = {
  name: '${clusterName}-deploy'
  params: {
    clusterName: clusterName
    location: location
    virtualNetworkName: 'Vnet'
    AKSsubnetName: 'AksSubnet'
    agentCount: agentCount
    agentVMSize: agentVMSize
    PrivateCluster: PrivateCluster
    virtualMachineName: virtualMachineName
  }
  dependsOn: [
    vnet
    vm
  ]
}

module db 'modules/postgresql.bicep' = {
  name: '${databaseName}-deploy' 
  params: {
    databaseName: databaseName
    location: location
    virtualNetworkName: 'Vnet'
    subnetName: 'DbSubnet'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  dependsOn: [
    vnet
  ]
}

module acr 'modules/acr.bicep' = {
  name: '${acrName}-deploy'
  params: {
    acrName: acrName
    location: location
    virtualNetworkName: 'Vnet'
    subnetName: 'AcrSubnet'
    clusterName: clusterName
    virtualMachineName: virtualMachineName
  }
  dependsOn: [
    vnet
    aks
  ]
}