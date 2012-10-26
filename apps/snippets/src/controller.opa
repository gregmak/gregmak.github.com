module Controller {

    default_json = Resource.json({String : "ERROR DURING REQUEST PARSING"});

    function make_resource(snippet) {
	Resource.json(OpaSerialize.Json.serialize(snippet));
    }

    function save_snippet(snippet) {
    	Model.save_snippet(snippet, function (snippet) {
	    make_resource(snippet);
    	});
    }

    function create_snippet() {
    	Toto.get_and_parse("model", default_json, function (model) {
	    Toto.unserialize_default_string(model, default_json, function(value) {
    		snippet = Model.make_snippet(value.title, value.code, value.user);
    		save_snippet(snippet);
	    });
    	});
    }

    function update_snippet() {
    	jlog("\nupdate snippet");
    	Toto.get_and_parse("model", default_json, function (model) {
    	    jlog("get and parse OK = {model}");
    	    Toto.partial_unserialize_default(model, default_json, function (json) {
    		jlog("partial unserialize default OK = {json}");
    		Toto.unserialize_default_json_unsorted(json, default_json, function(snippet) {
    		    jlog("unserialize default json OK = {snippet}");
    		    save_snippet(snippet);
    		});
    	    });
    	});
    }

    function delete_snippet() {
	jlog("\ndelete snippet'");
	Toto.get_and_parse("model", default_json, function (model) {
	    jlog("get and parse OK = {model}'");
	    Toto.unserialize_default_string(model, default_json, function (value) {
		jlog("unserialize default string = {value}'");
    		Model.delete_snippet({some: value.id}, function(res){
		    Resource.json({String : res});
    		});
	    });
	});
    }

    // function get_snippet(path) {
    // 	Toto.get_and_parse_path(path, "model", default_json, function(value) {
    // 	    Model.find_by_id({some: value.id}, default_json, function (snippet) {
    // 		Resource.json(OpaSerialize.Json.serialize(snippet));
    // 	    });
    // 	});
    // }

    function get_snippet(path) {
    	p = parser {
    		| s = UriParser.query ->
		match (List.assoc("model", s)) {
		case {some: value} :
    		    match (Json.deserialize(value)) {
    		    case {some: {Record: [(_, {Int : id})]}}:
    			match (Model.find_by_id({some: id})) {
			case {some: snippet} : make_resource(snippet);
			default : default_json;
			};
		    default : default_json
		    };
		default: default_json
		};
    		| (.*) -> default_json
    	};
    	Parser.parse(p, path);
    }

    function get_all_snippets() {
        Model.find_all(function(snippets){
	    list = List.map((function(snippet) {OpaSerialize.Json.serialize(snippet)}), snippets);
	    Resource.json({List : list})
	});
    }

    /*  THE SERVER WITH THE DISPATCHER */

    dispatcher = parser {
    	    | "/" -> View.simple_main_page()
    	    | "/snippets" -> get_all_snippets();
    	    | "/snippet" path=(.*) -> {
    		match (HttpRequest.get_method()) {
    		case {some: {post}}: create_snippet();
    		case {some: {put}}: update_snippet();
    		case {some: {get}}: get_snippet(Text.to_string(path));
    		case {some: {delete}}: delete_snippet();
    		default: default_json
    		}
    	    }
    	    | (.*) -> Resource.page("Hello", <><h2>"404 NOT FOUND!"</h2></>)
    }

}

Server.start(Server.http, {custom : Controller.dispatcher})

