module View {

    function initialize() {
	snippet_one = Model.make_snippet("essai 1","//FOO","gregmak");
	snippet_two = Model.make_snippet("essai 2","//Hello World","gregmak");
	snippet_three = Model.make_snippet("essai 3","//Me again !","gregmak");

	function foo(snippet) {
	    display_snippet(snippet);
	};

	Model.save_snippet(snippet_one, foo);
	Model.save_snippet(snippet_two, foo);
	Model.save_snippet(snippet_three, foo);

    }

    function display_snippet(snippet) {
	content =
	    <li>
            <h2>{snippet.title} by {snippet.user}</h2><br>
	    <div>{Markdown.xhtml_of_string({detect_text_links: true}, snippet.code)}</div>
	    </li>;
	Dom.transform([{jq : #snippet-list, subject : {content : content}, verb : {append}}])
    }

    function add_snippet() {
	title = Dom.get_value(#title);
	code = Dom.get_value(#code);
	user = Dom.get_value(#user);
	if (title == "" || code == "" || user == "") {
	    message = {alert : {title : "Error", description : <> All fields are mandatory. Please fill them all. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {error});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
	} else {
	    snippet = Model.make_snippet(title, code, user);
	    Model.save_snippet(snippet, function(snippet) {
		Dom.clear_value(#title);
		Dom.clear_value(#code);
		Dom.clear_value(#user);
		display_snippet(snippet);
	    });
	}
    }

    function simple_main_page() {
	title_bar =
	    <>
	    <div class="navbar navbar-fixed-top">
	    <div class="navbar-inner">
            <div class="container">
            <a class="brand" href="#">
	    <>OPA</>
	    </a>
            </div>
	    </div>
	    </div>
	    </>;
	form =
	    <>
	    <div id="snippet-form" style="margin-top:50px;">
            <h2>Go ...</h2>
	    <form method="post" action="javascript:void(0);" class="well">
            <label>Title : </label>
            <input id="title" type="text" class="span3" placeholder="title"/>
            <label>Code Snippet : (with markdown) </label>
            <textarea id="code" placeholder="code" style="width:100%" rows="5"></textarea>
            <label>User : </label>
            <input id="user" type="text" placeholder="user"/>
            <button type="submit" class="btn" onclick={function(_) {add_snippet()}}>Ajouter un Snippet</button>
	    </form>
	    </div>
	    </>;
	content =
	    <div onready={function(_) {initialize()}}>
	    {title_bar}
	    <div class="container">
	    <div>{form}</div>
	    <ul id="snippet-list" style="list-style: none;">
	    <li data-template>
            <hr>
	    </li>
	    </ul>
	    </div>
	    <div id="notifications">
	    </div>
	    </div>;
	Resource.page("StyKKeKode in OPA", content)
    }

}
