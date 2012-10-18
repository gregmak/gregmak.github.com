Travaillant chez **MLstate**, la compagnie ayant développé le framework JavaScript **Opa** basé sur **Node.js**, j'ai trouvé intéressant de présenter quelques tutoriels et comparatifs avec d'autres frameworks JS.

Le but de ces tutoriels est de montrer comment **Opa** se compare à d'autres frameworks (tels que **Express.js** ou **Backbone.js**) et quels sont ses avantages que les autres n'ont pas forcément (tels que le typage statique ou encore le *slicing* : découpe automatique du code entre **code client** et **code serveur**).

## Création d'un web-service **RESTful**.

Le premier de ces tutoriels portera sur la gestion en **Opa** des requêtes HTTP de type **REST** et permettra de comparer **Opa** avec **Express.js**, framework facilitant le développement de services **RESTful** en JavaScript.

Pour ce faire, nous allons écrire une petite application permettant de traiter des requêtes **REST** telles que **POST**, **PUT**, **DELETE** et **GET** et de manipuler des ressources en conséquence.
Cette application est inspirée de celle développée par **k33g_org** et dont vous pouvez voir le tutoriel à l'adresse http://k33g.github.com/2012/02/19/EXPRESSJS_IS_PLAY.html.

#### Pre-requis.

Vous devez bien sûr installer **Opa**, téléchargeable directement depuis le site d'[opalang](http://opalang.org), ou depuis le [repo github d'opalang](https://github.com/MLstate/opalang).

Uns fois **Opa** téléchargé et installé, vous devriez avoir tout ce dont vous avez besoin. Il n'y a pas d'autres dépendances à installer (**Node.js** étant automatiquement installé par **Opa** s'il n'est pas détecté durant la phase de configuration).

#### Le squelette de l'application.

**Opa** est livré avec un outil permettant de générer un squelette d'application basé sur le modèle **MVC**.

Ouvrez une console, placez vous à l'endroit souhaité et tappez simplement

```opa create snippets```

où *snippets* est le nom de notre application.

Cela va créer un repertoire *snippets* comprenant le squelette de notre application (pour plus de détails sur cet outil, regardez [l'article de Cédric Soulas sur le blog d'opalang](http://blog.opalang.org/2012/06/programming-tools-ux-how-we-simplified.html)).

#### La configuration.

Un fichier nommé ```opa.conf``` est placé à la racine de l'application et décrit les importations nécessaires pour chaque fichier, que ce soit l'importation d'éléments de la librairie standard d'**Opa** ou d'un des autres fichiers source de l'application. Éditez ce fichier et modifier-le comme ceci :

```javascript
snippets.controller:
	import snippets.view
	import snippets.model // nouvelle ligne ajoutée
	src/controller.opa

snippets.view:
	import snippets.model
	import stdlib.themes.bootstrap
	src/view.opa

snippets.model:
	src/model.opa
```

En ajoutant la ligne ```import snippets.model```, nous avons indiqué au compilateur que le module **Controller** du fichier ```src/controller.opa``` a besoin de connaître certaines fonctions définies dans le module **Model** du fichier ```src/model.opa```.

Notez que ces déclarations peuvent aussi bien se faire en début de chaque fichier. Mais l'utilisation d'un fichier ```opa.conf``` a l'avantage de centraliser toutes les déclarations de ce type.

#### Le modèle.

Une fois le squelette créé, nous commençons par modifier le fichier ```src/model.opa``` pour y inclure la définition d'un *snippet* et les traitements associés.

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

Ce fichier ne présente pas de grandes difficultés si vous êtes familiers avec **Opa** et la programmation fonctionnelle.

La seule particularité est l'utilisation du **UserContext**. Ce module, appartenant à la librairie standard d'**Opa**, est un des moyens offerts par **Opa** permettant la création et la manipulation d'éléments mutables.

#### La vue.

Nous allons maintenant éditer le ficher ```src/view.opa``` pour définir la structure de la page.

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
	<div onready={function(_) {initialize()}}> // on initialise la liste de snippets au chargement de la page
	</div>;
    Resource.page("Hello", content)
}
```
Notez ici que vous pouvez écrire directement du code HTML dans du code **Opa**. La création de pages web en **Opa** n'etant pas le sujet de ce tutoriel, nous nous contenterons d'une simple page vierge suffisante au bon déroulement de notre application. Il faut juste penser à créer les premiers *snippets* au chargement de la page.

#### Le contrôleur.

Il nous reste maintenant à gérer la définition du serveur, le dispatcheur (ou routeur) et le traitements des requêtes **REST**.
Cela se fait dans le fichier ```src/controller.opa```, que nous allons éditer et modifier comme cela :

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

Ce fichier présente plusieurs concepts clés que nous allons regarder de plus près.

#####Le traitement des requêtes et méthodes HTTP :

Un serveur **Opa** est associé à un gestionnaire d'URL, ou routes. La gestion des routes se fait via un *parser* d'**URL** : en fonction de l'**URL** reçue on redirige vers des traitements ou des pages spécifiques. C'est  l'équivalent **Opa** de l'objet **app.routes** de **Express.js** et de la classe **Router** de **Backbone.js**. La variable *dispatcher* s'occupe de cela.

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

La gestion des requêtes de type **REST** se fait ici en récupérant la méthode associée à la requête reçue (grâce à la fonction **HttpRequest.get_method()** de la librairie standard d'**Opa**) et d'effectuer un traitement spécifique en fonction de la méthode employée. On effectue pour ce faire un *pattern-matching* sur le résultat renvoyé : en fonction du résultat retourné, on applique une fonction spécifique.

Par exemple, dans le cas de la réception d'une requête **POST**, la fonction **HttpRequest.get_method()** retourne la valeur ```{some : {post}}``` et l'on voit que le *dispatcher* associe à cette valeur la fonction **create_snippet** :

```javascript
case {some : {post}}: create_snippet();
```

Regardons plus en détails le code de cette fonction :

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

La fonction **create_snippet** fait un appel à la fonction **parse_query** en lui donnant une fonction de traitement (que nous allons détailler plus loin). Regardons d'abord le corps de la fonction **parse_query** :

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

Nous avons besoin de récupérer le corps de la requête (grâce à la fonction **HttpRequest.get_body()** de la librairie standard d'**Opa**). Une fois ce corps récupéré, il faut l'analyser pour en extraire les éléments constituants la requête, ce qui est fait ici grâce à un *parser* d'**URI**, et enfin appliquer une fonction de traitement (*callback*, donné en paramètre de la fonction) sur ces éléments.

#####Le traitement des données JSON.

Nous venons de voir comment les éléments constituants la requête avaient été récupérés. Regardons maintenant comment nous pouvons manipuler ces éléments.

Reprenons le code de la fonction **create_snippet** :

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

Les éléments constituants la requête sont récupérés sous la forme d'une chaîne de caractères représentant une donnée au format JSON. Nous devons donc décoder cette chaîne de caractères pour récupérer un élément manipulable. Cela est fait par l'appel à la fonction **OpaSerialize.String.unserialize** qui prend en paramètre la chaîne de caractères et retourne un *record* correspondant. Nous pouvons donc maintenant créer un nouveau *snippet* à partir des champs **title**, **code** et **user** du *record* précédemment créé, et le sauvegarder.

Notez que l'on peut aussi, à partir d'une chaîne de caractères représentant un objet d'un type Opa connu décrit au format JSON, construire directement l'objet correspondant. Cela est par exemple fait dans la fonction **update_snippet** :

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

A partir de la chaîne de caractères, on construit un objet de type *RPC.Json.json* grâce à la fonction **OpaSerialize.partial_unserialize**. Il nous reste à décoder cet objet grâce à la fonction **OpaSerialize.Json.unserialize_unsorted** (*unsorted* car les champs dans la requête ne sont pas triés). Nous obtenons alors directement un objet du type *Snippet.t* que nous pouvons donc sauvegarder.



#### Testons cette application.

Nous avons donc terminé notre petite application, c'est le moment de la tester.
Ouvrez un navigateur internet, ouvrez la console JavaScript et entrez les commandes suivantes :

##### Création de snippet.

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

![post.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v1/post.png?raw=true)

On remarque que le serveur nous a renvoyé l'objet créé avec un nouvel *id* associé. Comme nous avions défini 3 *snippets*, le nouveau *snippet* a été créé avec l'*id* 4.

##### Mise à jour de snippet.

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

![put.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v1/put.png?raw=true)

Le serveur nous a renvoyé l'objet avec le champ *user* ayant la nouvelle valeur.

##### Recherche de snippet.

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

![get.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v1/get.png?raw=true)

Le serveur nous a bien renvoyé le *snippet* d'*id* 1.

##### Suppression de snippet.

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

![delete.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v1/delete.png?raw=true)

##### Liste de tous les snippet.

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

![getAll.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v1/getAll.png?raw=true)

Le serveur nous a renvoyé une liste de 3 *snippets*, le *snippet* d'*id* 1 ayant été supprimé précédemment.

#### Conclusion.

Nous venons de voir comment gérer les requêtes **REST** en **Opa** en comparaison de ce qui est fait par le framework **Express.js**.

Nous verrons dans d'autres tutoriels comment :
- manipuler le **DOM** afin de synchroniser les modèles et les vues associées,
- gérer la persistance via l'utilisation d'une base de données **NoSQL** (en l'occurrence **MongoDB**),
- etc.