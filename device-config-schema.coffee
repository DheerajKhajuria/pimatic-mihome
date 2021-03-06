module.exports = {
  title: "MiHome device config schemes"
  AirPurifier: {
    title: "Mi-Purifier config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:
      type:
        description: "The unique id of the node that sends or should receive the message"
        type: "string"
      model:
        description: "This is the child-sensor-ids that uniquely identifies one attached sensor"
        type: "string"
      token:
         description: "Show battery level with Sensors"
         type: "string"
      autotoken:
         description: "Show battery level with Sensors"
         type: "string"    
      address:
         description: "Show battery level with Sensors"
         type: "string"   
  }
}