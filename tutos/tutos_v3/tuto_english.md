## Persistence with MongoDB.

We will see in this tutorial how to manage persistence in **Opa** through the use of a NoSQL database : **MongoDB**.
We will start from the small application previously written and we will modify it so that the created *snippets* are stored in a database rather than in RAM.

#### The model.

This time the code of the model has changed compared to the first version.
We have to declare our database, and all the functions needed to manipulate *snippets* through this database.

```javascript
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
	snippet = find_by_id(id);
	Db.remove(@/test/snippets[{id: snippet.id}]);
	// applying the callback onto the found snippet
	callback(snippet);
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

````

This code begins with the declaration of the type of a *snippet*. We see that a *snippet* is comopsed by an identifier, a title, a code and the name of the creator.

```javascript
type Snippet.t = {option(int) id, string title, string code, string user}
```

All these fields exept the identifier are string. The identifier is an optional integer (which means that it can be omitted).

Once the data type(s) defined, we have to declare the structure of our databse.

````javascript
database test {
    Snippet.t /snippets[{id}] // the set of snippets
}
````

We have just declared a database with *test* as name and composed by a unique path : */snippets[{id}]* used to store datas of the type *Snippet.t*.
This declaration means that we want to store *snippets* as a set with the field *id* as primary key.

Let us have a closer look on the functions used to maniulate the *snippets*

##### The *snippets* search.

We define here a method to get all the *snippets* contained in the database and a method to get a *snippet* from its identifier.

````javascript
    function find_all(callback) {
	it = DbSet.iterator(/test/snippets);
	snippets = Iter.to_list(it);
	callback(snippets);
    }

    function find_by_id(id) {
	    /test/snippets[{id: {some: id}}];
    }
````

These two functions take as argument the callback to apply one the recovered *snippet(s)*.

The method to get all the *snippets* reads the whole set of *snippets* on the path *test/snippets*as a *DbSet*.
We want to be able to manipulate these *snippets* as a list, so we need to transform the DbSet into a list of *snippets*, what we do through the use of an iterator.

The method to get a particular *snippet* takes beside the id of the wanted *snippet*.
This method looks in the set of *snippets* and applyies the callback on the recovered *snippet*.

###### Beware !!!

Each path of a database declaration is associated with a default value.
If there is no data stored on the given path, the default value associated with this path is returned.
This is why a database read on a valid path always return a result.
We will see that point in the part of this tutorial dedicated to the view.

##### The *snippets* saving.

````javascript
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
````

As previously written, the *snippets* will be recorded in the database with their identifier as primary key.
The identifier of a *snippet* is an optional integer (which means that it can be omitted as it is during a new *snippet* creation).
So we need to handle both of these cases when saving a *snippet* :

1. The case where the identifier has a value (saving an existing *snippet*).
2. The case where the identifier has no value (saving a new *snippet*).

Hence we perform a pattern-matching on the identifier of the *snippet* to save.

In the case where the identifier has a value, we just have to overwrite the stored *snippet* by the new one and apply the callback on it :

````javascript
	/test/snippets[{id : snippet.id}] <- snippet;
	callback(snippet);
````

This declaration means that we want to store the value *snippet* at the path */tests/snippets[{id: snippet.id}]*.
If a previous *snippet* were already stored at this path then it would be overwritten. Otherwise, we have simply added a new value to the database.

In the case where the identifier has no value, we have to create a new one and assign it to the *snippet* to save.
For that we need to know the number of *snippets* currently contained in the database. Once again this will be done through the use of an iterator.

````javascript
	    size = Iter.count(DbSet.iterator(/test/snippets));
````

Once the number of *snippets* known, we can create the new id by taking the next integer following this numberand so we can be sure that each *snippet* contained in the database is going to have a unique id.

````javascript
	    id = {some : size + 1};
````

We just have now to assign this new id to our new *snippet* and record this *snippet* in the databse with the new id as primary key, and apply the callback on it.

````javascript
	snippet = {snippet with ~id};
	/test/snippets[{id: id}] <- snippet;
	callback(snippet);
````

##### The *snippets* deletion.

````javascript
    function delete_snippet(id, callback) {
	if (Db.exists(@/test/snippets[{id: {some: id}}])) {
	    Db.remove(@/test/snippets[{id: {some: id}}]);
	    callback({ok});
	} else {
	    callback({ko});
	}
    }
````

The deletion of a *snippet* is not very complex.
We have to test if the *snippet* with the giving id exists in the database.
If it exists, we delete it and apply the callback on the value {ok}. If not, we apply the callback on the value {ko}.
We will see what to do with such values later on.

##### Initialization.

At the start of the server, we check the content of the database by a call to the function **find_all**.
If the returned list is empty, we create 3 new *snippets* to fill the database and we display them.
Otherwise, the database is already filled with some *snippets* that we display.

````javascript
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
````

#### The view.

````javascript
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
	    <input id="snippet_id_show" class="snippet-id" type="text" placeholder="id"/>
	    </div>
	    <div>
	    <button type="submit"  class="btn" onclick={function(_) {delete_snippet()}}>Delete snippet of id</button>
	    <input id="snippet_id_delete" class="snippet-id" type="text" placeholder="id"/>
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
````

The view has some tiny changes compare to the previous version on DOM manipulation.
It contains some additional functions that we are going to detail.

#####Display all the *snippets*.

````javascript
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
````

We recover the list of all the *snippets* contained in the database by a call to the function **find_all** and for each *snippet* we call the function **display_snippet**.
For the first *snippet* to display, we give the value {set} to the function **display_snippet** so that this display must overwrite the pervious display.
Thereafter we use the value {append} to tell the function **display_snippet** that the following displays will be added to the first one.

#####Display a particular *snippet*.

````javascript
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
````

To display a particular *snippet*, we need to get its identifier given by the user in the field *snippet_id_show* (please refer to the previous tutorial for moer details about the DOM manipulation).
Once this id recovered wa call the function **find_by_id** from the model and we apply a particular treatment according to the returned value.

We have previously precised that any read on a valid path of a database declaration will always return a result (default value if no value is written on this path).
So we need to check to content of the returned value to make sure that this is not the default value, but a real *snippet* found on the given path.
We perform this check on the field *title* to be sure it is not an empty string as it would be for the default value.
If the title is not empty, we call the function **display_snippet** with the value {set} to overwrite the pervious display.

````javascript
	    display_snippet(snippet, {set});
````

If the title is an empty string; we display an error message to tell the user that the *snippet* he was looking for has not been found.

````javascript
	    message = {alert : {title : "Error", description : <> Snippet of id {id} does not exist. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {success});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
````

In every cases, we clean the form from the value read in the field *snippet_id_show* :

````javascript
	    Dom.clear_value(#snippet_id_show);
````

#####Delete a particular *snippet*.

````javascript
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
````

The same way we display a particular *snippet*, we can ask for a deletion.
Again, if the *snippet* to be removed does not exists in the database, we display an error message to the user. Otherwise we perform the deletion and apply the callback.

#### The controler.

````javascript
module Controller {

    dispatcher = parser {
    	    | "/" -> View.simple_main_page()
    	    | (.*) -> Resource.page("Hello", <><h2>"404 NOT FOUND!"</h2></>)
    }

}

resources = @static_resource_directory("resources")

Server.start(Server.http, [
  { register:
    [ { doctype: { html5 } },
      { js: [ ] },
      { css: [ "/resources/css/style.css"] }
    ]
  },
  { ~resources },
  { custom: Controller.dispatcher }
])

````

The code of the controler is quite similar to the one of the previous version.
We have added the loading of the file *style.css* in which we have defined the style for some elements in our page.

#### Let us test this application.

Once the application compiled and running, open your browser at the address ````localhost:8080```` which is the default address.
We can see that the page already displays the 3 *snippets* we have created at the start of the server.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_1.png?raw=true)

We can now create a new snippet.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_2.png?raw=true)

Click on the button 'Add a snippet'.
The page now displays the 4 *snippets* contained in the database.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_3.png?raw=true)

Let's now test the display of a particular *snippet*.
Enter "3" in the input field after the button 'Show snippet of id', and validate either by clicking on that button or press 'Enter'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_4.png?raw=true)

We can see that only the *snippet* with the identifier "3" is displayed.

Let's now test the deletion of a *snippet*.
Enter "4" in the input field after the button 'Delete snippet of id', and validate either by clicking on that button or press 'Enter'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_5.png?raw=true)

A message confirms that the deletion has been done.
Let's check that.
Let's ask to display only the *snippet* of identifier "4", which is the *snippet* we have just deleted.
Enter "4" in the input field after the button 'Show snippet of id', and validate either by clicking on that button or press 'Enter'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_6.png?raw=true)

We can see that a message tells us that the *snippet* we are looking for does not exists.

Let us now ask for the display of all the *snippets* contained in the database.
Click on the button 'Show all snippets'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_7.png?raw=true)

We can see only 3 *snippets* displayed. The *snippet* of identifier "4" has been deleted from the database.

#### Conclusion.

We have seen how to handle persistence in *Opa* through the use of a NoSQL database : MongoDB.