type Snippet.t = {option(int) id, string title, string code, string user}

module Model {

    // the user context that will store the list of snippets
    UserContext.t(list(Snippet.t)) snippets = UserContext.make([]);

    function make_snippet(title, code, user) {
	{id: {none}, ~title, ~code, ~user}
    }

    function save_snippet(snippet, callback) {
	match (snippet.id) {
	case {some : id}: // existing snippet
	    UserContext.change((function(snippets) {
		snippets = List.remove_p((function(snippet) {snippet.id == {some: id}}), snippets);
		List.cons(snippet, snippets);
	    }), snippets);
	    // applying the callback onto the given snippet
	    callback(snippet);
	default: // new snippet
	    l = UserContext.execute((function(snippets) {List.length(snippets)}), snippets);
	    id = if (l >= 5) {some : 1} else {some : l + 1}
	    snippet = {snippet with ~id}
	    UserContext.change((function(snippets) {
		// the list is reinitiallized every 5 snippets
		if (l >= 5) [snippet]
		else List.cons(snippet, snippets)
	    }), snippets);
	    // applying the callback onto the updated snippet
	    callback(snippet);
	};
    }

    function delete_snippet(id, callback) {
	match (find_by_id(id)) {
	case {some: snippet} :
	    UserContext.change((function(snippets) {
		List.remove_p((function(snippet) {snippet.id == id}), snippets);
	    }), snippets);
	    // applying the callback onto the found snippet
	    callback(snippet);
	default : Resource.source("\{\"toto\":\"ERROR\"}", "application/json");
	}
    }

    function find_all(callback) {
	UserContext.execute((function(snippets) {
	    callback(snippets);
	}), snippets);
    }

    function find_by_id(id) {
	UserContext.execute((function(snippets) {
	    List.find((function(snippet) {snippet.id == id}), snippets);
	}), snippets);
    }

}
