module Toto {

    // To be added to HttpRequest module
    function get_and_parse(key, def, callback) {
    	match (HttpRequest.get_body()) {
	case {some : body} -> {
    	    p = parser {
    		    | s = UriParser.query_element -> {
			match (s) {
			case (k, value) : if (k == key) {callback(value);} else def;
			default : def;
			}
		    }
		    | (.*) -> def;
	    };
	    Parser.parse(p, body)
	}
	default : def;
	}
    }

    // To be added to OpaSerialize.String module
    function unserialize_default_string(value, def, callback) {
	match (OpaSerialize.String.unserialize(value)) {
    	case {some: value} : callback(value)
    	default : def
    	}
    }

    // To be added to OpaSerialize.Json module
    function unserialize_default_json(value, def, callback) {
	match (OpaSerialize.Json.unserialize(value)) {
    	case {some: value} : callback(value)
    	default : def
	}
    }

    // To be added to OpaSerialize.Json module
    function unserialize_default_json_unsorted(value, def, callback) {
	match (OpaSerialize.Json.unserialize_unsorted(value)) {
    	case {some: value} : callback(value)
    	default : def
	}
    }

    // To be added to OpaSerialize module
    function partial_unserialize_default(value, def, callback) {
	match (OpaSerialize.partial_unserialize(value)) {
	case {some: value} : callback(value);
	default : def;
	}
    }

}