module View {

    function initialize() {
	Model.initialize(display_snippet);
    }

    function display_snippet(snippet, verb) {
	content =
	    <li>
            <h2>{snippet.title} by {snippet.user}</h2><br>
	    <div>{Xhtml.of_string_unsafe(snippet.code)}</div>
	    </li>;
	Dom.transform([{jq : #snippet-list, subject : {content : content}, ~verb}])
    }

    function add_snippet() {
	title = Dom.get_value(#title);
	code = Dom.get_value(#code)
	    |> Markdown.xhtml_of_string({detect_text_links: true}, _)
	    |> Xhtml.to_string(_);
	user = Dom.get_value(#user);
	if (title == "" || code == "" || user == "") {
	    message = {alert : {title : "Erreur", description : <> All fields are mandatory. Please fill them all. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {error});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
	} else {
	    snippet = Model.make_snippet(title, code, user);
	    Model.save_snippet(snippet, function(snippet) {
		Dom.clear_value(#title);
		Dom.clear_value(#code);
		Dom.clear_value(#user);
		display_snippet(snippet, {append});
	    });
	}
    }

    function show_all() {
	Model.find_all(function(snippets) {
	    List.iteri(function(i, snippet) {
		if (i == 0) {
		    display_snippet(snippet, {set});
		} else {
		    display_snippet(snippet, {append});
		}
	    }, snippets)
	})
    }

    function show_snippet() {
	id = Dom.get_value(#snippet_id_show) |> Int.of_string(_)
	snippet = Model.find_by_id(id);
	if (snippet.title == "") {
	    message = {alert : {title : "Error", description : <> Snippet of id {id} does not exist. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {success});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
	    Dom.clear_value(#snippet_id_show);
	} else {
	    display_snippet(snippet, {set});
	    Dom.clear_value(#snippet_id_show);
	}
    }

    function delete_snippet() {
	id = Dom.get_value(#snippet_id_delete) |> Int.of_string(_)
	Model.delete_snippet(id, function(result) {
	    match (result) {
	    case {ok} :
		message = {alert : {title : "OK", description : <> Snippet of id {id} has been removed. </>}, closable : true};
		alert = WBootstrap.Alert.make(message, {success});
		Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
		Dom.clear_value(#snippet_id_delete);
	    case {ko} :
		message = {alert : {title : "Error", description : <> Snippet of id {id} does not exist. </>}, closable : true};
		alert = WBootstrap.Alert.make(message, {success});
		Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
		Dom.clear_value(#snippet_id_delete);
	    }
	})
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
            <textarea id="code" placeholder="code" rows="5"></textarea>
            <label>User : </label>
            <input id="user" type="text" placeholder="user"/>
            <button type="submit" class="btn" onclick={function(_) {add_snippet()}}>Add a Snippet</button>
	    </form>
	    </div>
	    </>;
	boutons =
	    <>
	    <div><button type="submit"  class="btn" onclick={function(_) {show_all()}}>Show all snippets</button></div>
	    <div>
	    <button type="submit"  class="btn" onclick={function(_) {show_snippet()}}>Show snippet of id</button>
	    <input id="snippet_id_show" class="snippet-id" type="text" placeholder="id" onnewline={function(_) {show_snippet()}} />
	    </div>
	    <div>
	    <button type="submit"  class="btn" onclick={function(_) {delete_snippet()}}>Delete snippet of id</button>
	    <input id="snippet_id_delete" class="snippet-id" type="text" placeholder="id" onnewline={function(_) {delete_snippet()}}/>
	    </div>
	    </>;
	content =
	    <div onready={function(_) {initialize()}}>
	    {title_bar}
	    <div class="container">
	    <div>{form}</div>
	    <div>{boutons}</div>
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
