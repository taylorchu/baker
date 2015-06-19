---
---
<!DOCTYPE html>
<html>
<head>
@include bootstrap
@include head
<title>{{ SITE_NAME }}</title>
</head>

<main class="container">
	<header>
	<h1>{{ SITE_NAME }}</h1>
	{{ SITE_DESC }}
	</header>

	<section class="row">
		<section class="col-md-6">
@for post in posts
			<article>
				<h2><a href="{{ post_id }}.html">{{ post_title }}</a></h2>
				<p class="post-date">Published on <time>{{ post_date }}</time></p>
				<p>{{ post_summary }}</p>
			</article>
@end
		</section>
		<section class="col-md-2">
			<img class="author-avatar pull-right" src="http://www.gravatar.com/avatar/{{ AUTHOR_EMAIL_HASH }}" />
		</section>
		<section class="col-md-4">
			<p class="author-name">{{ AUTHOR_NAME }}</p>
			<p class="author-desc">{{ AUTHOR_DESC }}</p>
			<p class="author-email">{{ AUTHOR_EMAIL }}</p>

			<img src="image/baker.png" />
		</section>
	</section>

	<footer class="text-center">
		A <a href="http://github.com/taylorchu/baker">baker</a> blog.
	</footer>
</main>

</html>
