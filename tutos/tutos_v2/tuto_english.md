## DOM manipulation.

In this tutorial we will see how to manipulate the DOM in **Opa**.
For that we are going to modify the application we wrote for the previous tutorial, for :

1. allow the user to create his *snippets* through a form rather than from **REST** requests.
2. the *snippets* to be displayed in the web page rather than in the browser console.

#### The model.

The code of the model doesn't change from previous version (refer to the previous tutorial if you want to see the code of the model).
So we will skip directly to the view, or how to handle the web page display.

#### The view.

We will now edit the file ```src.view.opa``` to define the web page structure.
This structure has changed since we now want to display the *snippets* within the page.

```javascript
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
	code = Dom.get_value(#code)
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
            <button type="submit" class="btn" onclick={function(_) {add_snippet()}}>Add a Snippet</button>
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
```

##### The web page structure.

We can see the the page is now composed of a title bar, a form to create the *snippets* and a place to display them.

The title bar is used to give the page a rendering and to display a permanent link to one of the page of the application (for instance the home page).

The form creation is quite easy if you are familiar with HTML forms.
We need to precise the method used to send datas to the server : **get** or **post** (since this tutorial is not about the differences between these two methods we will not see them in details here).
We need three input fields (for the *snippet* title and code and for the user name), and a button to submit the form and send datats to the server.
The *snippet* title and the user name will be written in two simple **input** and the *snippet* code in a **textarea**.
To the submission button we associate the method **add_snippet** which will read datas in the form fields and send them back to the server so that it can create a new *snippet*.

Let us have a closer look to this function.

##### Datas reading.

````javascript
    function add_snippet() {
	title = Dom.get_value(#title);
	code = Dom.get_value(#code)
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
````

DOM manipulation is made in **Opa** with functions from the Dom module from the standard library.
Reading datas from an element of the web page is done throught the method **Dom.get_value** which takes as argument an element f the web page and returns a string.
In this exemple we will use ids to identify the wanted elements.
This is not the only way to do this (even not the best in the way that implies to handle ids carefully to avoid any duplication).

Let us take the *snippet* title as an exmple.

In the form structure wa have defined the input field this way :
````javascript
<input id="title" type="text" class="span3" placeholder="title"/>
````

Wa gave him the id  *title* : ```id="title"```.

We can now read the title given by the user throught a call to the function **Dom.get_value** with the field of id *title* as argument :
````javascript
title = Dom.get_value(#title)
````
(similary to JQuery, the synatx *#id* refers to the element if id *id* within the web page if it exists).

Once all the needed datas recoveried, we can send them to the server for it to create a new *snippet*, and then clean all the form fields and update the view so that it is synchronized with the model.

````javascript
	    snippet = Model.make_snippet(title, code, user);
	    Model.save_snippet(snippet, function(snippet) {
		Dom.clear_value(#title);
		Dom.clear_value(#code);
		Dom.clear_value(#user);
		display_snippet(snippet);
	    });
````

The update of the *snippets* list display is maid throught the call to the function **dispay_snippet** with the new *snippet* to display given as argument.

Let us take a closer look to this function.

##### The view update.

````javascipt
    function display_snippet(snippet) {
	content =
	    <li>
            <h2>{snippet.title} by {snippet.user}</h2><br>
	    <div>{Markdown.xhtml_of_string({detect_text_links: true}, snippet.code)}</div>
	    </li>;
	Dom.transform([{jq : #snippet-list, subject : {content : content}, verb : {append}}])
    }
````

The view update according to the model is quite simple.
We just have to build the new element to be inserted within the web page and then we update the *snippets* list with this new element.

When creating the web page, we have defined a place where to display the *snippets* contained in the model :

````javascript
	    <ul id="snippet-list" style="list-style: none;">
	    <li data-template>
            <hr>
	    </li>
	    </ul>
````

We just need to tell the DOM that this list is going to have one more element, the new *snippet*, which is done this way :

````javascript
Dom.transform([{jq : #snippet-list, subject : {content : content}, verb : {append}}])
````

The fnuction **Dom.transform** takes as first argument an element of the web page to be modified (here get through its id *snippet-list*), and as second argument the way to modify it (this can be either an adding at the end, an adding at the begenning or a replacement).
In this exemple we use the value ```{append}``` which means that we want to add content at the end.

##### Error management.

We have added in this exemple a first level of error management.

If all the fields are not filled, an error message is displayed at the bottom of the page to let the user know that something went wrong, and no data is send to the server.
This allows to control the form structure on the client side without any request send to the server to see that some datas are missing.
This does not allow to get rid of a more careful control of the datas on the server side, especially to check their content to avoid any security threats.

````javascript
	if (title == "" || code == "" || user == "") {
	    message = {alert : {title : "Error", description : <> All fields are mandatory. Please fill them all. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {error});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
	}
````

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/snippets_v2_error_server.png?raw=true)

#### The controler.

In this exemple the code of the controler is more simpler and shorter since we dont have any more to handle **REST** requests as we had to in the previous tutorial.
A simple URL parser is sufficient to have our application running (we only have one page to display).

````javascript
module Controller {

    dispatcher = parser {
    	    | "/" -> View.simple_main_page()
    	    | (.*) -> Resource.page("Hello", <><h2>"404 NOT FOUND!"</h2></>)
    }

}

Server.start(Server.http, {custom : Controller.dispatcher})
````

#### Let us test this application.

Once the application compiled and running, open your web brower at the address ```localhost:8080`` which is the default address of your server.
You can see that the web page already displays the 3 *snippets* created at the server start.
The model and the view are synchronized when the server starts.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/snippets_v2_1.png?raw=true)

Enter a title and a code for your new *snippet* and your name, and then click on the button 'Add a snippet'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/snippets_v2_2.png?raw=true)

You cna see that the view has been updated with your new *snippet* displayed in the top of the list.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/snippets_v2_3.png?raw=true)

#### Conclusion.

We have seen how to manipulate the DOM and synchronize a view and a model in **Opa** compare to how this is done by the framework **Backbone.js**.

We will see in some further tutorials how :
- to manage persistence through a **NoSQL** database (in this case **MongoDB**),
- etc.
