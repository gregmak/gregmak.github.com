type Snippet.t = {option(int) id, string title, string code, string user}

module Model {

    // the user context that will store the list of snippets
    UserContext.t(list(Snippet.t)) snippets = UserContext.make([]);

    function get_size() {
	UserContext.execute((function(snippets) {List.length(snippets)}), snippets);
    }

    function make_snippet(title, code, user) {
	{id: {none}, ~title, ~code, ~user}
    }

    function save_snippet(snippet, callback) {
	id = snippet.id ? (1 + get_size());
	snippet = {snippet with id : {some : id}}
	UserContext.change((function(snippets) {
	    List.cons(snippet, snippets)
	}), snippets);
	// apply the callback on the updated snippet
	callback(snippet);
    }

    function delete_snippet(id, callback) {
	size = get_size();
	UserContext.change((function(snippets) {
	    List.remove_p((function(snippet) {snippet.id == id}), snippets);
	}), snippets);
	if (get_size() == size) {
	    callback("FAIL TO DELETE SNIPPET OF ID {id}");
	} else {
	    callback("SNIPPET OF ID {id} SUCCESSFULLY DELETED");
	}
    }

    function find_all(callback) {
	UserContext.execute((function(snippets) {
	    callback(snippets);
	}), snippets);
    }

    function find_by_id(id) {
	UserContext.execute((function(snippets) {
	    List.find(function (snippet) {snippet.id == id}, snippets)
	}), snippets);
    }

}
