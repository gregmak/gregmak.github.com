## How the buil **RESTful** web service in **Opa**.

This tutorial will show how to handle in **Opa** HTTP requests of type **REST** and will allow us to compare **Opa** with **Express.js**, framework that makes easier the developpement of web services **RESTful** in JavaScript.

For that, we will write a small application that allow to handle **REST** requests such as **POST**, **PUT**, **DELETE** and **GET** and to manipulate resources accordingly.
This application is inspired from the one developped by **k33g_org** and for which you can see the tutorial at http://k33g.github.com/2012/02/19/EXPRESSJS_IS_PLAY.html.

#### Prerequisite.

You need to intall **Opa**, downloadable from the [opalang](http://opalang.org) website, or from the [github repo of opalang](https://github.com/MLstate/opalang).

Once **Opa** installed, you should have everything you need. There is no other dependencies to install (**Node.js** is automatically installed if it is not detected during configuration).

#### Application skeleton.

**Opa** comes with a tool that allow you to generate a skeleton of an application, based on the MVC model.

Open a terminal at the place you want, and just write

```opa create snippets```

where *snippets* is the name of the application.

This will create a directory *snippets* containing the application skeleton (for more details on this tool, see the [article from Cédric Soulas on the opalang blog](http://blog.opalang.org/2012/06/programming-tools-ux-how-we-simplified.html)).

#### Configuration.

A file nammed ```opa.conf``` is placed at the root of the application and describes the needed importations for each file, wether it is elements from the **Opa** standard library or one of the other source file of the application. Edit this file and modify it like this :

```javascript
snippets.controller:
	import snippets.view
	import snippets.model // new line added
	src/controller.opa

snippets.view:
	import snippets.model
	import stdlib.themes.bootstrap
	src/view.opa

snippets.model:
	src/model.opa
```

Adding the line ```import snippets.model``` indicates to the compiler that the module **Controller** from the file ```src/controller.opa``` needs to access some functions defined in the module **Model** from the file ```src/model.opa```.

Note that these declarations could have been placed at the begening of each file. But using the file ```opa.conf``` has the advantage to centralize all these declarations.

#### The model.

Once the skeleton created, we are going to modify the file ```src/model.opa``` to include the definition of a *snippet* and the related functions.

```javascript
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
```

This file does not present any difficulties if you are familiar with **Opa** and/or the functional programming.

The code begins with the declaration of the type of a *snippet*. We see that a *snippet* is comopsed by an identifier, a title, a code and the name of the creator.
The only particularity is the use of the **UserContext**. This module, bellonging to the **Opa** standard library, is one way **Opa** offers to allow to create mutable elements.

#### The view.

We are now going to edit the file ```src/view.opa``` to define the page structure.

```javascript
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
	<div onready={function(_) {initialize()}}> // we initialize the list of *snippets* when the page has been loaded
	</div>;
    Resource.page("Hello", content)
}
```

Note that you can directly write HTML code inside **Opa** code. The web page creation in **Opa** is not the topic of this tutorial, so we will set with a simple white page, enough to correctly run the application. We just need to fill the *snippet* list when the page is loaded.

#### The controler.

We now have to to define the server, the dispatcheur and the treatments of the **REST** requests.
This will be done in the file ```src/controller.opa```, which we are going to modify like this :

```javascript
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
```

This file presents several key concepts that we are going to look closer.

#####Treatment of HTTP requests and methods :

An **Opa** server is associated with an URL handler, which is an URL parser : according to the received URL, we redirect to specific treatments or pages.
This is the equivalent of the **app.routes** object of **Express.js** and of the class **Router** of **Backbone.js**. The *dispatcher* variable handles this.

```javascript
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
```

We handle **REST** type requests by getting the associated method (with the function **HttpRequest.get_method** of the **Opa** standard library) and performing a specific treatment accordingly.
For that, we perform a *pattern-matching* on the returned result.

For instance, in the case of the request **POST**, the function **HttpRequest.get_method** returns ```{some : {post}}``` and we can see that the *dispatcher* associates to this value the function **create_snippet** :

```javascript
case {some : {post}}: create_snippet();
```

Let's have a closer look to this function :

```javascript
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
```

The function **create_snippet** make a call to the function **parse_query** and give it the treatment function (which we will see later).
Let's first have a look at the function **parse_query** :

```javascript
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
```

We first need to get the body of the request (with the function **HttpRequest.get_body** of the **Opa** standard library).
Once this body recovered, we need to analyze it to get the elements constituting the request, which is made with an **URI** parser, and last, apply the treatment function (*callback*, given as parameter) on these elements.

#####Treatment of JSON datas.

We have seen how the elements constituting the request have been recovered.
Let's now see how we can manipulate these elements.

Remember the code of the function **create_snippet** :

```javascript
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
```

The elements constituting the request are recovered as a string representing a data with the JSON format.
So we have to deserialize this string to recover a manipulated element.
This is made by the call to the function **OpaSerialize.String.unserialize** that takes as argument a string and returns a corresponding *record*.
We can now create a new *snippet* from the fields **title**, **code** and **user** from the new created *record*, and save it.

Note that we can also, from a string representing an object of a known type described with the JSON format, directly build the corresponding object.
This is made, for exemple, in the funciton **update_snippet** :

```javascript
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
```

From the string, we make an object of type *RPC.Json.json* with the function **OpaSerialize.partial_unserialize**.
We have now to deserialize this object with the function **OpaSerialize.Json.unserialize_unsorted** (*unsorted* because the fields inside the request are not sorted).
And we finally get an object of type *Snippet.t* we can now save.

#### Let's test this application.

We have completed the small application, it is time to test it.
Once the application compiled and running, open your web brower at the address ```localhost:8080`` which is the default address of your server.
Open the JavaScript console, and enter the following commands :

##### Snippet creation.

```javascript
$.ajax({
    type: "POST",
    url: "/snippet",
    data: {"model":JSON.stringify({
        title:"Hello World",
        code : "println('Hello world')",
        user : "@gregmak"
    })},
    dataType: 'json',
    error: function () {
        console.log("oups");
    },
    success: function (dataFromServer) {
        console.log(dataFromServer);
    }
});
```

![post.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/post.png?raw=true)

We can notice that the server returns the object with a new *id* associated.
Since we already have defined 3 *snippets*, the new one has been created with *id* 4.

##### Snippet update.

```javascript
$.ajax({
    type: "PUT",
    url: "/snippet",
    data: {"model":JSON.stringify({
        id : {some : 4}, /*vérifier que l'id existe*/
        title:"Hello World",
        code : "println('Hello world $name')",
        user : "@GREGMAK"
    })},
    dataType: 'json',
    error: function () {
        console.log("oups");
    },
    success: function (dataFromServer) {
        console.log(dataFromServer);
    }
});
```

![put.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/put.png?raw=true)

The server returns the object with the field *user* set at the new value.

##### Searching a snippet.

```javascript
$.ajax({
    type: "GET",
    url: "/snippet",
    data: {"model":JSON.stringify({id:1})},
    dataType: 'json',
    error: function () {
        console.log("oups");
    },
    success: function (dataFromServer) {
        console.log(dataFromServer);
    }
});
```

![get.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/get.png?raw=true)

The server returns the object of *id* 1.

##### Snippet deletion.

```javascript
$.ajax({
    type: "DELETE",
    url: "/snippet",
    data: {"model":JSON.stringify({id:1})},
    dataType: 'json',
    error: function () {
        console.log("oups");
    },
    success: function (dataFromServer) {
        console.log(dataFromServer);
    }
});
```

![delete.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/delete.png?raw=true)

##### Getting all the snippets.

```javascript
$.ajax({
    type: "GET",
    url: "/snippets",
    data: null,
    dataType: 'json',
    error: function () {
        console.log("oups");
    },
    success: function (dataFromServer) {
        dataFromServer.forEach(function(model){
            console.log(model)
        });
    }
});
```

![getAll.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/getAll.png?raw=true)

The server returns a list of 3 *snippets*, since *snippet* of *id* 1 has been previously deleted.

#### Conclusion.

We have seen how to handle **REST** in **Opa** compared to what it is done by the **Express.js** framework.

We will see in other tutorials how :
- manipulate the **DOM** to synchronise models and associated views,
- handle persistence by using a **NoSQL** database (we have choosen for that **MongoDB**),
- etc.