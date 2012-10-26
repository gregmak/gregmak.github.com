module View {

    function initialize() {
	function make_and_save(title, code, user) {
	    Model.save_snippet(Model.make_snippet(title, code, user), function(_) {void});
	};
	make_and_save("essai 1","//FOO","gregmak");
	make_and_save("essai 2","//Hello World","gregmak");
	make_and_save("essai 3","//Me again !","gregmak");
    }

    function simple_main_page() {
	content =
	    <div>
	    <h2 onready={function(_) {initialize()}}>"Opa VS Express.js"</h2>
	    </div>;
	Resource.page("Hello", content)
    }

}
