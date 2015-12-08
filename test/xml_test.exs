defmodule XmlTest do
  use ExUnit.Case
  doctest Xml

  require Record

  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlAttribute, Record.extract(:xmlAttribute, from_lib: "xmerl/include/xmerl.hrl")

  def sample_xml do
	doc = """
	  <html>
		<head>
		  <title>XML Parsing</title>
		</head>
		<body>
		  <p>Neato</p>
		  <ul>
			<li msg="hello" msg2="fubar">First</li>
			<li msg="world">Second</li>
		  </ul>
		</body>
	  </html>
	"""

	{xml, _} = doc
	  |> :binary.bin_to_list
	  |> :xmerl_scan.string()

	xml
  end

  test "parsing the title tag" do
	[title_element] = :xmerl_xpath.string('/html/head/title', sample_xml)
	[title_text] = xmlElement(title_element, :content)
	title = xmlText(title_text, :value)

	assert title == 'XML Parsing'
  end

  test "parsing the ul items" do
	items = :xmerl_xpath.string('/html/body/ul/li', sample_xml)
	  |> Enum.map(fn(x) ->
		[text] = xmlElement(x, :content)
		xmlText(text, :value)
	  end)

	assert items == ['First', 'Second']
  end

  test "parsing the attributes of the ul items" do
	items = :xmerl_xpath.string('/html/body/ul/li', sample_xml)
	  |> Enum.map(fn(x) ->
		xmlElement(x, :attributes)
		  |> Enum.map(fn(y) -> xmlAttribute(y, :value) end)
	  end)
	  |> Enum.concat()

	assert items == ['hello', 'fubar', 'world']
  end

  test "parsing the attributes of the ul items and getting a tuple" do
	items = :xmerl_xpath.string('/html/body/ul/li', sample_xml)
	  |> Enum.map(fn(x) ->
		xmlElement(x, :attributes)
		  |> Enum.map(fn(y) -> {xmlAttribute(y, :name), xmlAttribute(y, :value)} end)
	  end)
	  |> Enum.concat()

	# assert items == [{'msg', 'hello'}, {'msg2', 'fubar'}, {'msg', 'world'}]
	assert items == [msg: 'hello', msg2: 'fubar', msg: 'world']
  end

  test "parsing children of elements" do
	[ul] = :xmerl_xpath.string('/html/body/ul', sample_xml)

	items = xmlElement(ul, :content)
	  |> Enum.filter(fn(x) ->
		elem(x, 0) == :xmlElement
	  end)
	  |> Enum.map(fn(x) ->
		Atom.to_char_list(xmlElement(x, :name))
	  end)

	assert items == ['li', 'li']
  end
end
