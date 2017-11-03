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
            address = result.addres

            # Check if device already exists in pimatic
            newdevice = not @framework.deviceManager.devicesConfig.some (device, iterator) =>
            device.type is type and device.model is model and device.autotoken is autotoken and device.token is token and device.address is address

            # Device is a new device and not a battery device
            if newdevice is true
            # air purifier device found
            if sensortype is AIR_PURIFIER
              config = {
                class: 'MySensorsDST',
                type: type,
                model: model,
                autotoken: autotoken,
                token: token,
                address: address
              }
              @framework.deviceManager.discoveredDevice(
                'pimatic-mihome', "Temp Sensor #{type}.#{address}", config
              )
            )
      )

  # ###Finally
  # Create a instance of my plugin
  myMiHome = new MiHome
  # and return it to the framework.
  return myMiHome