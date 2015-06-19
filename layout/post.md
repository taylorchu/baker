---
---
<!DOCTYPE html>
<html>
<head>
@include bootstrap
@include head
<title>{{ title }} - {{ SITE_NAME }}</title>
</head>

<main class="container">
	<header>
	<nav>
		<ul class="nav nav-pills pull-right">
			<li class="active"><a href="index.html">Home</a></li>
			<li><a href="#author">About</a></li>
		</ul>
	</nav>
	<h1>{{ title }}</h1>
	</header>

	<article>
		{{ yield }}
	</article>

	<footer id="author" class="row">
		<section class="col-md-5">
			<p class="post-date">Published on <time>{{ date }}</time></p>
		</section>
		<section class="col-md-2">
			<img alt="author-avatar" class="author-avatar pull-right" src="http://www.gravatar.com/avatar/{{ AUTHOR_EMAIL_HASH }}" />
		</section>
		<section class="col-md-5">
			<p class="author-name">{{ AUTHOR_NAME }}</p>
			<p class="author-desc">{{ AUTHOR_DESC }}</p>
			<p class="author-email">{{ AUTHOR_EMAIL }}</p>
		</section>
	</footer>
@include disqus
</main>

</html>
