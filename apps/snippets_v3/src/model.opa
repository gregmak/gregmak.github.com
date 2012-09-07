type Snippet.t = {option(int) id, string title, string code, string user}

database test {
    Snippet.t /snippets[{id}] // the set of snippets
}

module Model {

    function make_snippet(title, code, user) {
	{id: {none}, ~title, ~code, ~user}
    }

    function save_snippet(snippet, callback) {
	match (snippet.id) {
	case {some : _}:
		/test/snippets[{id : snippet.id}] <- snippet;
	    // applying the callback onto the given snippet
	    callback(snippet);
	default: // new snippet
	    size = Iter.count(DbSet.iterator(/test/snippets));
	    id = {some : size + 1};
	    snippet = {snippet with ~id};
		/test/snippets[{id: id}] <- snippet;
	    // applying the callback onto the updated snippet
	    callback(snippet);
	}
    }

    function find_all(callback) {
	it = DbSet.iterator(/test/snippets);
	snippets = Iter.to_list(it);
	callback(snippets);
    }

    function find_by_id(id) {
	    /test/snippets[{id: {some: id}}];
    }

    function delete_snippet(id, callback) {
	if (Db.exists(@/test/snippets[{id: {some: id}}])) {
	    Db.remove(@/test/snippets[{id: {some: id}}]);
	    callback({ok});
	} else {
	    callback({ko});
	}
    }

    function initialize(callback) {
	function callback(snippet) {
	    callback(snippet, {append});
	}
	find_all(function(snippets) {
	    if (List.is_empty(snippets)) {
		snippet_one = make_snippet("essai 1","//FOO","gregmak");
		snippet_two = make_snippet("essai 2","//Hello World","gregmak");
		snippet_three = make_snippet("essai 3","//Me again !","gregmak");
		save_snippet(snippet_one, callback);
		save_snippet(snippet_two, callback);
		save_snippet(snippet_three, callback);
	    } else {
		List.iter(function(snippet) {
		    callback(snippet);
		}, snippets)
	    }
	})
    }

}
