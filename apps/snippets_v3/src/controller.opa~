module Controller {

    function save_snippet(snippet) {
    	Model.save_snippet(snippet, function(snippet){
    	    Resource.json(OpaSerialize.Json.serialize(snippet));
    	})
    }

    function parse_query(callback) {
    	match (HttpRequest.get_body()) {
	case {some : body} -> {
    	    p = parser {
    		    | s = UriParser.query_element -> {
			match (s) {
			case ("model", model) : callback(model);
			default : Resource.json({String : "ERROR DURING REQUEST PARSING"});
			}
		    }
		    | (.*) -> Resource.json({String : "ERROR DURING REQUEST PARSING"});
	    };
	    Parser.parse(p, body)
	}
	default : Resource.json({String : "ERROR DURING REQUEST PARSING"});
	}
    }

    function create_snippet() {
    	parse_query(function(model) {
    	    match (OpaSerialize.String.unserialize(model)) {
    	    case {some: value} :
    		snippet = Model.make_snippet(value.title, value.code, value.user);
    		save_snippet(snippet);
    	    default : error("error during snippet creation");
    	    }
    	})
    }

    function update_snippet() {
	parse_query(function(model) {
	    match (OpaSerialize.partial_unserialize(model)) {
	    case {some : json} :
    		match (OpaSerialize.Json.unserialize_unsorted(json)) {
    		case {some: snippet} : save_snippet(snippet)
    		default : error("error during snippet update");
    		}
	    default:  error("error during snippet update");
	    }
	})
    }

    function delete_snippet() {
	parse_query(function(model) {
    	    match (OpaSerialize.String.unserialize(model)) {
    	    case {some: value} :
    		Model.delete_snippet({some: value.id}, function(snippet){
		    Resource.json(OpaSerialize.Json.serialize(snippet));
    		});
    	    default: error("error during snippet deletion");
    	    }
	})
    }

    function get_snippet(path) {
    	p = parser {
    		| s = UriParser.query ->
    		match (s) {
    		case [("model", model) | _] -> {
    		    match (Json.deserialize(model)) {
    		    case {some: {Record: [(_, {Int : id})]}}:
    			match (Model.find_by_id({some: id})) {
    			case {some: snippet} : Resource.json(OpaSerialize.Json.serialize(snippet));
    			default : error("error during snippet get");
    			};
    		    default: error("error during snippet get");
    		    };
    		}
    		default -> error("error during snippet get")
		}
    		| (.*) -> Resource.source("\{\"toto\":\"POST KO\"}", "application/json");
    	};
    	Parser.parse(p, path);
    }

    function get_all_snippets() {
        Model.find_all(function(snippets){
	    list = List.map((function(snippet) {OpaSerialize.Json.serialize(snippet)}), snippets);
	    Resource.json({List : list})
	});
    }

    /*  LE SERVEUR AVEC LE GESTIONNAIRE DE REQUETES */

    dispatcher = parser {
    	    | "/" -> View.simple_main_page()
    	    | "/snippets" -> get_all_snippets();
    	    | "/snippet" path=(.*) -> {
    		match (HttpRequest.get_method()) {
    		case {some: {post}}: create_snippet();
    		case {some: {put}}: update_snippet();
    		case {some: {get}}: get_snippet(Text.to_string(path));
    		case {some: {delete}}: delete_snippet();
    		default: error("error during method inspection");
    		}
    	    }
    	    | (.*) -> Resource.page("Hello", <><h2>"404 NOT FOUND!"</h2></>)
    }

}

Server.start(Server.http, {custom : Controller.dispatcher})

