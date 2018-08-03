Cypress.Cookies.defaults({
  whitelist: "foo1"
})

context "cookies", ->
  beforeEach ->
    cy.wrap({foo: "bar"})

  it "can get all cookies", ->
    cy
      .clearCookie("foo1")
      .setCookie("foo", "bar").then (c) ->
        expect(c.domain).to.eq("localhost")
        expect(c.httpOnly).to.eq(false)
        expect(c.name).to.eq("foo")
        expect(c.value).to.eq("bar")
        expect(c.path).to.eq("/")
        expect(c.secure).to.eq(false)
        expect(c.expiry).to.be.a("number")

        expect(c).to.have.keys(
          "domain", "name", "value", "path", "secure", "httpOnly", "expiry"
        )
      .getCookies()
        .should("have.length", 1)
        .then (cookies) ->
          c = cookies[0]

          expect(c.domain).to.eq("localhost")
          expect(c.httpOnly).to.eq(false)
          expect(c.name).to.eq("foo")
          expect(c.value).to.eq("bar")
          expect(c.path).to.eq("/")
          expect(c.secure).to.eq(false)
          expect(c.expiry).to.be.a("number")

          expect(c).to.have.keys(
            "domain", "name", "value", "path", "secure", "httpOnly", "expiry"
          )
      .clearCookies()
        .should("be.null")
      .setCookie("wtf", "bob", {httpOnly: true, path: "/foo", secure: true})
      .getCookie("wtf").then (c) ->
        expect(c.domain).to.eq("localhost")
        expect(c.httpOnly).to.eq(true)
        expect(c.name).to.eq("wtf")
        expect(c.value).to.eq("bob")
        expect(c.path).to.eq("/foo")
        expect(c.secure).to.eq(true)
        expect(c.expiry).to.be.a("number")

        expect(c).to.have.keys(
          "domain", "name", "value", "path", "secure", "httpOnly", "expiry"
        )
      .clearCookie("wtf")
        .should("be.null")
      .getCookie("doesNotExist")
        .should("be.null")
      .document()
        .its("cookie")
        .should("be.empty")

  it "resets cookies between tests correctly", ->
    Cypress.Cookies.preserveOnce("foo2")

    for i in [1..100]
      do (i) ->
        cy.setCookie("foo" + i, "#{i}")

    cy.getCookies().should("have.length", 100)

  it "should be only two left now", ->
    cy.getCookies().should("have.length", 2)

  it "sends cookies to localhost:2121", ->
    cy
      .clearCookies()
      .setCookie("asdf", "jkl")
      .request("http://localhost:2121/foo")
        .its("body").should("deep.eq", {foo1: "1", asdf: "jkl"})

  it "handles expired cookies", ->
    cy
      .visit("http://localhost:2121/set")
      .getCookie("shouldExpire").should("exist")
      .visit("http://localhost:2121/expirationMaxAge")
      .getCookie("shouldExpire").should("not.exist")
      .visit("http://localhost:2121/set")
      .getCookie("shouldExpire").should("exist")
      .visit("http://localhost:2121/expirationExpires")
      .getCookie("shouldExpire").should("not.exist")

  it "issue: #224 sets expired cookies between redirects", ->
    cy
      .visit("http://localhost:2121/set")
      .getCookie("shouldExpire").should("exist")
      .visit("http://localhost:2121/expirationRedirect")
      .url().should("include", "/logout")
      .getCookie("shouldExpire").should("not.exist")

      .visit("http://localhost:2121/set")
      .getCookie("shouldExpire").should("exist")
      .request("http://localhost:2121/expirationRedirect")
      .getCookie("shouldExpire").should("not.exist")
