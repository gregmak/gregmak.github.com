## Manipulation du DOM.

Nous allons voir dans ce tutoriel comment manipuler le DOM en **Opa**.
Pour ce faire nous allons reprendre l'application ecrite précédamment et nous allons la modifier pour :

1. permettre à l'utilisateur de créer ses *snippets* via un formulaire plutôt que via des requêtes **REST**
2. que les *snippets* soient affichés dans la page web plutôt que dans la console du navigateur.

Nous avons donc besoin d'une part d'un formulaire et d'autre part d'afficher une liste de *snippets* qui va se mettre à jour au fur et à mesure des créations de *snippets*.

#### Le modèle.

Le code du modèle ne change pas.
Nous allons donc passer directement à la vue, c'est-à-dire la gestion de l'affichage de la page web.
Reportez-vous au précédent tutoriel pour voir le code du modèle.

#### La vue.

Nous allons maintenant éditer le ficher ```src/view.opa``` pour définir la structure de la page.
Cette structure a changé car nous voulons maintenant afficher les *snippets* crées directement dans la page web.

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
```

##### La structure de la page.

Nous voyons que la structure de la page est un peu plus complèxe que dans le tutoriel précédent, dans lequel nous nous contentions d'une simple page blanche.
Notre page se compose maintenant d'une barre de titre, d'un formulaire de création de *snippets* et d'un emplacement pour afficherla liste des *snippets*.

La barre de titre sert à donner un rendu à la page et permet d'avoir un lien permanent vers une des pages (par exemple la page d'acceuil) de l'application.

La création du formulaire ne présente pas de difficultés particulières si vous avez déjà ecrits des formulaires HTML.
Il vous faut préciser la méthode à utiliser pour envoyer les données vers le serveur : **get** ou **post** (ce tutoriel ne portant pas sur les différences entre ces méthodes, je ne les détaillerai pas ici), puis définir les champs qui composeront votre formulaire.
Nous avons besoin ici de 3 champs de saisie (pour le titre du *snippet*, le code du *snippet* et le nom de l'utilisateur), ainsi que d'un bouton pour valider le formulaire et envoyer les données au serveur.
Le titre et le nom de l'utilisateur seront renseignés dans deux **input** et le code du *snippet* dans un **textarea**.
Au bouton de soumission est associée la méthode **add_snippet()** qui va lire les données dans les champs du formulaire et les envoyer au serveur pour que celui-ci puisse créer un nouveau *snippet*.

Regardons le code de cette fonction plus en détails.

##### La récupération d'informations.

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

La manipulation du DOM se fait en **Opa** via les fonctions du module Dom de la librairie standard.
La récupération d'informations dans une page web se fait grâce à la méthode **Dom.get_value** qui prend en paramètre un élément de type **dom** et retourne une chaîne de caractères.
Dans notre exemple, nous nous servons des identifiants pour récupérer les valeurs qui nous interressent. Ce n'est pas la seule façon de faire
(ni même forcément la meilleure dans le sens où cela neccessite une gestion rigoureuse des identifiants pour éviter toute dupplication).

Prenons l'exemple du titre du *snipet*.
Dans la structure du formulaire nous avons déclaré le champ de saisie ainsi : ```<input id="title" type="text" class="span3" placeholder="title"/>```.
Nous lui avons donc associé l'identifiant *title* : ```id="title"```.
Nous récupérons le titre entré par l'appel à la fonction Dom.get_value() en lui donnant en paramètre le champ concerné, ici récupéré via son identifiant *title* : ```Dom.get_value(#title)````
(simillairement à JQuery, la syntaxe *#id* fait référence à l'élément d'identifiant *id* contenu dans la page s'il existe).
Les champs récupérés peuvent se manipuler directement, sans traitement particulier, sous forme de chaîne de caractères car ils sont de ce type dans notr définition du type d'un *snippet*.

Une fois toues les données necessaires récupérées, nous les envoyons au serveur afin qu'il créé un nouveau *snippet*, puis efface les données du formulaire et met à jour la vue pour qu'elle soit synchronisée avec le modèle.

````javascript
	    snippet = Model.make_snippet(title, code, user);
	    Model.save_snippet(snippet, function(snippet) {
		Dom.clear_value(#title);
		Dom.clear_value(#code);
		Dom.clear_value(#user);
		display_snippet(snippet);
	    });
````

La mise à jour de l'affichage de la liste des *snippets* se fait par l'appel à la fonction **dispay_snippet** en lui donnant en paramètre le *sippet* à afficher en plus de ceux déjà affichés.

Regardons le code de cette fonction plus en détails.

##### La mise à jour de la vue.

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

La mise à jour de la vue en fonction du modèle est assez simple.
Nous construisons le nouvel élément à insérer puis nous mettons à jour la liste des snippets.

Nous avons défini à la création de notre page un endroit où afficher la liste des *snippets* contenus dans le modèle :

````javascript
	    <ul id="snippet-list" style="list-style: none;">
	    <li data-template>
            <hr>
	    </li>
	    </ul>
````

Nous avons juste besoin d'indiquer au DOM que cette liste va contenir un nouvel élément qui est le nouveau snippet.

````javascript
Dom.transform([{jq : #snippet-list, subject : {content : content}, verb : {append}}])
````

La fonction **Dom.transform** prend en argument un élément de type **dom** à modifier (que nous récupérons ici grâce à son identifiant *snippet-list*), et la façon de le modifier (cela peut être un ajout à la fin, un ajout au début ou un remplacement).
Dans notre exemple nous utilisons la valeur ```{append}``` qui indique que l'on veut ajouter du contenu à la fin.

##### Gestion d'erreurs.

Nous avons ajouté dans notre exemple un premier niveau de gestion d'erreur.
Dans le cas où tous les champs ne sont pas renseignés, un message d'erreur s'affiche sur la page web et aucune données n'est transmise au serveur.
Cela permet d'avoir un contrôle sur la structure du formulaire côté client, sans avoir besoin d'envoyer une requête au serveur pour s'appercevoir que des données sont manquantes.
Cela ne permet pas en revanche de s'affranchir d'un contrôle plus rigoureux des données côté serveur.

````javascript
	if (title == "" || code == "" || user == "") {
	    message = {alert : {title : "Error", description : <> All fields are mandatory. Please fill them all. </>}, closable : true};
	    alert = WBootstrap.Alert.make(message, {error});
	    Dom.transform([{jq : #notifications, subject : {content : alert}, verb : {set}}]);
	}
````

![snippets_v2_error_server.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v2/snippets_v2_error_server.png?raw=true)

#### Le controlleur.

Dans cette version le code du controlleur est beaucoup plus simple et court car nous n'avons plus besoin des traiter des requêtes **REST**.
Un simple parser d'URL permet de faire tourner notre application (nous n'avons qu'une page à servir).

````javascript
module Controller {

    dispatcher = parser {
    	    | "/" -> View.simple_main_page()
    	    | (.*) -> Resource.page("Hello", <><h2>"404 NOT FOUND!"</h2></>)
    }

}

Server.start(Server.http, {custom : Controller.dispatcher})
````

#### Testons cette application.

Une fois l'application compilée et lancée, ouvrez votre navigateur à l'adresse indiquée.
Vous voyez que la page affiche déjà les 3 *snippets* qu'on a créé au lancement du serveur. Le modèle et la vue sont donc bien synchronisés au démarrage du serveur.

![snippets_v2_1.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v2/snippets_v2_1.png?raw=true)

Entrez un titre et un code pour votre *sinppet*, votre nom et cliquez sur le bouton 'Ajouter un snippet'.

![snippets_v2_2.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v2/snippets_v2_2.png?raw=true)

Vous voyez que la vue a bien été mise à jour avec votre nouveau snippet affiché en fin de liste.

![snippets_v2_3.png](https://github.com/gregmak/gregmak.github.com/blob/master/images/v2/snippets_v2_3.png?raw=true)

#### Conclusion.

Nous venons de voir comment manipuler le DOM en **Opa** et comment synchroniser une vue et un modèle, en comparaison de ce qui est fait par le framework **Backbone.js**.

Nous verrons dans d'autres tutoriels comment :
- gérer la persistance via l'utilisation d'une base de données **NoSQL** (en l'occurrence **MongoDB**),
- etc.