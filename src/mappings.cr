require "json"

# own
class ConfigEntry
    include JSON::Serializable
  
    property distance : Int32?
    property pattern : String?
end

# pushift.io, minimized
class Source
    include JSON::Serializable

    property author : String
    property permalink : String
end

class Hit
    include JSON::Serializable

    property _source : Source
end

class Hits
    include JSON::Serializable

    property total : UInt64
    property hits : Array(Hit)
end

class Response
    include JSON::Serializable

    property hits : Hits
end