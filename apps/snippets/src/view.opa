module View {

    function initialize() {
	snippet_one = Model.make_snippet("essai 1","//FOO","gregmak");
	snippet_two = Model.make_snippet("essai 2","//Hello World","gregmak");
	snippet_three = Model.make_snippet("essai 3","//Me again !","gregmak");

	function foo(snippet) {
	    jlog(snippet.title);
	};

	Model.save_snippet(snippet_one, foo);
	Model.save_snippet(snippet_two, foo);
	Model.save_snippet(snippet_three, foo);

    }

    function simple_main_page() {
	content =
	    <div>
	    <h2 onready={function(_) {initialize()}}>"Opa VS Express.js"</h2>
	    </div>;
	Resource.page("Hello", content)
    }

}
