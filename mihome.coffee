# #Plugin template

# This is an plugin template and mini tutorial for creating pimatic plugins. It will explain the 
# basics of how the plugin system works and how a plugin should look like.

# ##The plugin code

# Your plugin must export a single function, that takes one argument and returns a instance of
# your plugin class. The parameter is an envirement object containing all pimatic related functions
# and classes. See the [startup.coffee](http://sweetpi.de/pimatic/docs/startup.html) for details.
module.exports = (env) ->

  AIR_PURIFIER               = 'air-purifier' 

  # ###require modules included in pimatic
  # To require modules that are included in pimatic use `env.require`. For available packages take 
  # a look at the dependencies section in pimatics package.json

  # Require the  bluebird promise library
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'

  # Include you own depencies with nodes global require function:
  #  
  #     someThing = require 'someThing'
  # 
  miio = require('miio')
  
  # ###MyPlugin class
  # Create a class that extends the Plugin class and implements the following functions:
  class MiHome extends env.plugins.Plugin

    # ####init()
    # The `init` function is called by the framework to ask your plugin to initialise.
    #  
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins` 
    #     section of the config.json file 
    #     
    # 
    init: (app, @framework, @config) =>
      env.logger.info("Starting to miHome Plugin.")

      deviceConfigDef = require("./device-config-schema")

      # Discover mihome devices
      @framework.deviceManager.on('discover', (eventData) =>
        @browser =  miio.browse({cacheTime: 1000})

        @framework.deviceManager.discoverMessage(
            'pimatic-mihome', "Searching for devices"
            )
        # Stop searching after configured time
        setTimeout(( =>
            @browser.removeListener("available", discoverListener)
            ), eventData.time)

        @browser.on('available', discoverListener = (result) =>
            env.logger.info(result)
            newdevice = true
            type = result.type
            model = result.model
            autotoken = result.autotoken
            token = result.token
            address = result.address

            # Check if device already exists in pimatic
            newdevice = not @framework.deviceManager.devicesConfig.some (device, iterator) =>
              device.type is type and device.model is model and device.autotoken is autotoken and device.token is token and device.address is address

            # Device is a new device 
            if newdevice
              # air purifier device found
              if type is AIR_PURIFIER
                config = {
                  class: 'AirPurifier',
                  type: type,
                  model: model,
                  autotoken: autotoken,
                  token: token,
                  address: address
                }
                @framework.deviceManager.discoveredDevice(
                  'pimatic-mihome', "AirPurifier #{type}.#{model}.#{address}", config
                )
         )
      )

      deviceClasses = [
          AirPurifier
        ]
    
      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config,lastState) =>
              device  =  new Cl(config,lastState)
              return device
            })    

  # Device class representing the power switch of the Denon AVR
  class AirPurifier extends env.devices.Device
    # Create a new DenonAvrPowerSwitch device
    # @param [Object] config    device configuration
    # @param [DenonAvrPlugin] plugin   plugin instance
    # @param [Object] lastState state information stored in database
    constructor: (@config,lastState) ->
      @id = @config.id
      @name = @config.name
      @properties = [
        power:  lastState?.power?.value
        mode: lastState?.mode?.value
        favoriteLevel: lastState?.favoriteLevel?.value
        temperature:  lastState?.temperature?.value
        humidity:  lastState?.humidity?.value
        aqi: lastState?.aqi?.value
        bright:  lastState?.bright?.value
        filterLifeRemaining:  lastState?.filterLifeRemaining?.value
        filterHoursUsed:  lastState?.filterHoursUsed?.value
        useTime:  lastState?.useTime?.value
        led: lastState?.led?.value
        ledBrightness:  lastState?.ledBrightness?.value
        buzzer:  lastState?.buzzer?.value
      ]
    
      @attributes = {}

      @attributes.aqi = {
        description: "Air Quality Index (PM 2.5)"
        type: "number"
        unit: ''
        acronym: 'aqi'
      }

      @attributes.temperature = {
        description: "The measured temperature"
        type: "number"
        unit: '°C'
        acronym: 'T'
      }

      @attributes.humidity = {
        description: "The measured humidity"
        type: "number"
        unit: '%'
        acronym: 'RH'
      }

      @attributes.filterLifeRemaining = {
        description: "Filter life remaining"
        type: "number"
        unit: '%'
        acronym: ''
      }
    
      @attributes.filterHoursUsed = {
        description: "Filter remaining days"
        type: "number"
        unit: 'days'
        acronym: ''
      }

      @attributes.useTime = {
        description: "Filter used hours"
        type: "number"
        unit: 'Hr'
        acronym: ''
      }


      @device = new miio.device(
       address: @config.address,
       type: @config.type,
       model: @config.model,
       )

      @device.then (device) => 
       env.logger.info ("Connected to the device")
       @deviceObj = device;
       # env.logger.info(device)
       for propertyName,value of device._properties
        @valueEventHandler ({property: propertyName,value})
       device.on 'propertyChanged',  @valueEventHandler

      @valueEventHandler = ( (result) =>
       env.logger.info(result)
       switch result.property
        when "useTime" 
         @properties[result.property] = result.value / 3600
        when "filterHoursUsed" 
         @properties[result.property] = Math.round(145 - result.value / 24)
        else
         @properties[result.property] = result.value
       @emit result.property, @properties[result.property]
       )

      super()

    destroy: ->
     @deviceObj.destroy();     
     super()
  
    getAqi: -> Promise.resolve @properties.aqi
    getTemperature: -> Promise.resolve @properties.temperatue
    getHumidity: -> Promise.resolve @properties.humidity
    getFilterLifeRemaining: -> Promise.resolve @properties.filterLifeRemaining
    getFilterHoursUsed: -> Promise.resolve @properties.filterHoursUsed
    getUseTime: -> Promise.resolve @properties.useTime 

  # ###Finally
  # Create a instance of my plugin
  myMiHome = new MiHome
  # and return it to the framework.
  return myMiHome