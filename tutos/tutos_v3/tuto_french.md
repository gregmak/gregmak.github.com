## Persistance avec MongoDB.

Nous allons voir dans ce tutoriel comment gérer la persistance en **Opa** via l'utilisation d'une base de données NoSQL : **MongoDB**.
Pour ce faire nous allons reprendre l'application ecrite précédamment et nous allons la modifier pour que les *snippets* créés soient stockés dans une base de données plutôt qu'en RAM.

#### Le modèle.

Cette fois le code du modèle va changer par rapport à la première version de l'application.
Nous y déclarons maintenant notre base de données, ainsi que toutes les fonctions de manipulation de *snippets*.

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

Ce code commence avec la déclaration du type d'un *snippet*. Nous voyons qu'ici un *snippet* est composé d'un identifiant, d'un titre, d'un code et d'un nom pour le créateur.

```javascript
type Snippet.t = {option(int) id, string title, string code, string user}
```

Tous ces champs sauf l'identifiant sont des chaînes de caractères. L'identifiant est un entier optionel (c'est-à-dire qu'il peut ne pas être précisé).

Uns fois le(s) type(s) de données définis, nous devons déclarer la structure de notre base de données.

````javascript
database test {
    Snippet.t /snippets[{id}] // the set of snippets
}
````

Nous venons de déclarer une base de données ayant pour nom *test* et ayant un seul chemin : */snippets[{id}]* servant à stocker des données du type *Snippet.t*.
Ici nous n'avons que des *snippets* à stocker, notre base peut dont se composer d'un chemin unique.
Cette déclaration indique que l'on veut stocker un *set* de *snippets* avec le champ *id* comme clé primaire.

Regardons plus en détail les fonctions de manipulation des *snippets*.

##### La recherche de *snippets*.

Nous définissons ici une méthode pour récupérer tous les *snippets* contenus dans la base et une méthode pour récupérer un *snippet* à partir de son identifiant.

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

Ces deux fonctions prennent en argument une continuation à appliquer unefois le(s) *snippet(s)* récupéré(s).

La méthode pour récupérer tous les *snippets* va lire l'ensmble des *snippets* sur le chemin */test/snippets* sous la forme d'un *DbSet*.
Nous voulons manipuler ces *snipets* sous forme de liste donc nous transformons notre *DbSet* en liste de *snippets* en passant par un *iterator*.

La méthode pour récupérer un *snippet* particulier prend en plus l'identifiant du *snippet* recherché.
Cette méthode va chercher dans l'ensemble des *snippets* et applique la continuation sur le *snippet* ayant l'identifiant recherché.

###### Attention !!!

Chaque chemin d'une déclaration de base de données est associée à une valeur par défaut.
Si aucune donnée n'est sotckée au chemin indiqué, la valeur par défaut associée à ce chemin sera retournée.
C'est pourquoi une lecture sur un chemin valide de la base de donneés retourne toujours un résultat.
C'est au programeur de faire attention, en manipulant le résultat retourner, à savoir s'il manipule cette valeur par défaut ou une valeur trouvée dans la base de données.
Nous reverrons ce point plus loin dans la partie sur la gestion de la vue.

##### La sauvegarde de *snippets*.

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

Comme nous l'avons indiqué précédamment, les *snippets* seront enregistrés dans la base de données avec leur identifiant comme clé primaire.
L'identifiant d'un *snippet* est un entier optionel (c'est-à-dire qu'il peut ne pas être rensigné comme c'est le cas à la création d'un nouveau *snippet*).
Nous devons donc traiter les deux cas lors de l'enregistrement d'un *snippet* :

1. Le cas où l'identifiant est rensigné (donc enregistrement d'un *snippet* existant).
2. Le cas où il n'est pas rensigné (donc enregistrement d'un nouveau *snippet*).

Nous effectuons donc un *pattern-matching* sur l'identifiant du *snippet* à sauvegarder.

Dans le cas où l'identifiant est renseigné, nous avons juste à écraser l'ancien *snippet* par le nouveau.

Dans le cas où l'identifiant n'est pas connu, nous devons en créér un nouveau et l'assigner au *snippet* à sauvegarder.
Pour ce faire nous avons besoin de connaitre le nombre de *snippets* actuellement contenu dans la base de données. Nous passons encore une fois par un *iterator*.

````javascript
	    size = Iter.count(DbSet.iterator(/test/snippets));
````

Une fois le nombre de *snippets* connus, nous pouvons créér notre nouvel identifiant en prennant l'entier suivant ce nombre et ainsi nous assurer que chaque *snippet* contenu dans la base aura bien un identifiant unique.

````javascript
	    id = {some : size + 1};
````

Il ne nous reste plus qu'a assigner ce nouvel identifiant à notre nouveau *snippet* et l'enregistrer dans la base avec cet identifiant comme clé primaire, puis appliquer la continuation.

````javascript
	snippet = {snippet with ~id};
	/test/snippets[{id: id}] <- snippet;
	callback(snippet);
````

##### La suppression de *snippets*.

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

La suppression d'un *snippet* n'est pas très compliquée.
Nous testons l'existence du *snippet* ayant l'identifiant donné. S'il existe, nous le supprimons et indiquons que la suppression a été faite (````callback({ok})````). Sinon, nous indiquons que la suppression ne s'est pas faire (````callback({ko})````).

#####L'initialisation.

Au démarrage de notre serveur, nous regardons le contenu de notre base de données par un appel à la fonction *find_all()*.
Si la liste retournée est vide, nous créons trois *snippets* pour remplir la base et nous les affichons.
Dans le cas contraire, la base est déjà remplie de quelques *snippets* que nous affichons.

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

#### La vue.

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

La vue ne change pas énormément comparé à la version précédente sur la manipulation du DOM en *Opa*.
Elle comporte quelques fonctions suplémentaires que vous allons détailler maintenant.

#####Affichage de tous les *snippets*.

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

Nous récupérons la liste de tous les *snippets* contenus dans la base par un appel à la fonction *find_all()* et pour chaque *snippet* contenu dans la liste nous appelons la fonction d'affichage *display_snippet()*.
Pour le 1er *snippet* à afficher nous passons la valeur {set} à la fonction *display_snippet()* pour lui indiquer que cet affichage doit écraser l'affichage précédent.
Par la suite nous utilisont la valeur {append} pour indiquer que les affichages suivants viendront s'ajouter au premier.

#####Affichage d'un *snippet*.

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

Pour afficher un *snippet* particulier, nous avons besoin de lire son identifiant renseigné par l'utilisateur dans le champ *snippet_id_show* (veuillez vous reporter au tutoriel sur la manipulation du DOM en *Opa* pour plus de détails sur ce sujet).
Une fois cet identifiant récupéré, nous appelons la fonction *find_by_id()* du modèle et nous appliquons un traitement particulier en fonction de la valeur retournée.

Nous avons précisé précédamment qu'une lecture sur un chemin de la base de données retournait toujours un résultat. Si aucune donnée ne se trouve sur un chemin donné, la valeur par défaut associée à ce chemin est retournée.
Nous devons donc regarder le conteunu de la valeur retournée pour nous assurer que ce n'est pas la valeur par défaut, mais bien un *snippet* trouvé sur le chemin donné.
Nous faisons le test ici uniquement sur le titre du *snippet* retourné pour nous assurer qu'il n'est pas vide, ce qui serait le cas pour la valeur par défaut.
Si le titre du *snippet* n'est pas vide, nous appelons la fonction d'affichage *display_snippet()* avec en paramètres le *snippet* retourné et la valeur {set} pour écraser l'affichage précédent :

````javascript
	    display_snippet(snippet, {set});
````

Si le titre du *snippet* est vide, nous affichons un message d'erreur pour indiquer à l'utilisateur que le *snippet* recherché n'a pas été trouvé.

````javascript
	    message = {alert : {title : "Error", description : <> Snippet of id {id} does not exist. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {success});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
````

Dans tous les cas, nous nettoyns le formulaire de la valeur lue dans le champ *snippet_id_show* :

````javascript
	    Dom.clear_value(#snippet_id_show);
````

#####Suppression d'un *snippet*.

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

Le méchanisme est similaire à celui décrit précédamment pour l'affichage d'un *snippet* particulier.
La différence réside dans le traitement effectué une fois l'action faite du côté du modèle.
Dans le cas de la suppression, nous affichons toujours un message à l'utilisateur pour lui indiquer si la suppression a bien été réalisée ou non.

#### Le controlleur.

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
Le code du controlleur ressemble fortement à celui de la précédente version. Nous lui ajoutons juste le chargement du fichier .css dans lequel nous avons défini le style pour quelques éléments de notre page.

#### Testons cette application.

Une fois l'application compliée et lancée, ouvrez votre navigateur à l'adresse ````localhost:8080```` qui est l'adresse par défaut.
Vous voyez que la page affiche déjà les 3 *snippets* que nous avons crées au démarrage du serveur.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_1.png?raw=true)

Nous créeons un nouveau snippet.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_2.png?raw=true)

La page affiche bien maintenant les 4 contenus dans la base.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_3.png?raw=true)

Testons maintent l'affichage d'un *snippet* en particulier.
Entrez la valeur "3" dans le champ de saisie à droite du bouton 'Show snippet of id', puis validez en cliquant sur le bouton ou en appuyant sur la toûche 'Entrée'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_4.png?raw=true)

Nous voyons que seul le *snippet* d'identifiant "3" est affiché.

Testons maintenant la suppression d'un *snippet*.
Entrez la valeur "4" dans le champ de saisie à droite du bouton 'Delete snippet of id', puis validez en cliquant sur le bouton ou en appuyant sur la toûche 'Entrée'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_5.png?raw=true)

Vérifions que la suppression a bien été éfféctuée.
Demandons l'affichage du *snippet* d'identifiant "4", soit celui que nous venons de supprimer.
Entrez la valeur "4" dans le champ de saisie à droite du bouton 'Show snippet of id', puis validez en cliquant sur le bouton ou en appuyant sur la toûche 'Entrée'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_6.png?raw=true)

Nous voyons que le système nous préviens que le *snippet* recherché n'existe pas.

Demandons maintenant l'affichage de tous les *snippets* contenus dans la base.
Cliquez sur le bouton 'Show all snippets'.

![snippets_v2_error_server_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v3/snippets_v3_7.png?raw=true)

Nous voyons bien que seulement 3 *snippets* sont affichés. Le *snippet* d'identifiant "4" a bien été supprimé de la base de données.


#### Conclusion.

Nous venons de voir comment gérer la persistance via l'utilisation d'une base de données **NoSQL** (en l'occurrence **MongoDB**),