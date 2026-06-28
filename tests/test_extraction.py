from policy_article_collector.extract import extract_article_text, extract_candidate_urls


def test_extract_article_text_prefers_main_content():
    html = """
    <html><head><title>Policy Title</title></head>
    <body><nav>Menu</nav><main><h1>Heading</h1><p>Useful policy body.</p></main></body></html>
    """
    title, text = extract_article_text(html)
    assert title == "Policy Title"
    assert "Useful policy body" in text


def test_extract_candidate_urls_scores_article_like_links():
    html = '<a href="/news/view?id=123">Important policy article</a><a href="/image.jpg">image</a>'
    urls = extract_candidate_urls(html, "https://example.com/list")
    assert urls == ["https://example.com/news/view?id=123"]