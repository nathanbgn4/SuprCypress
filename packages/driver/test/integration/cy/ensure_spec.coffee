{ $, _ } = window.testUtils

describe "$Cypress.Cy Ensure Extensions", ->
  enterCommandTestingMode()

  it "adds 4 methods", ->
    _.each ["Subject", "Parent", "Visibility", "Dom"], (name) =>
      expect(@cy["ensure" + name]).to.be.a("function")

  context "#ensureDom", ->
    beforeEach ->
      @allowErrors()

    it "stringifies node + references wiki", ->
      button = $("<button>foo</button>")

      fn = => @cy.ensureDom(button, "foo")

      expect(fn).to.throw("cy.foo() failed because this element you are chaining off of has become detached or removed from the DOM:\n\n<button>foo</button>\n\nhttps://on.cypress.io/element-has-detached-from-dom")

  context "#ensureElExistence", ->
    it "always unbinds before:log if assertion fails", ->
      fn = =>
        @cy.ensureElExistence($())

      expect(fn).to.throw("to exist in the DOM")
      expect(@cy.state("onBeforeLog")).to.be.null

  context "#ensureElementIsNotAnimating", ->
    beforeEach ->
      @allowErrors()

    it "returns early if waitForAnimations is false", ->
      @sandbox.stub(@Cypress, "config").withArgs("waitForAnimations").returns(false)

      fn = => @cy.ensureElementIsNotAnimating()

      expect(fn).not.to.throw(Error)

    it "throws without enough coords provided to calculate distance", ->
      fn = => @cy.ensureElementIsNotAnimating(null, [])
      expect(fn).to.throw("Not enough coord points provided to calculate distance")

    it "throws when element is animating", ->
      @cy.state("current", { get: -> "foo" })

      $el    = @cy.$$("button:first")
      coords = [{x: 10, y: 20}, {x: 20, y: 30}]

      fn = => @cy.ensureElementIsNotAnimating($el, coords)
      expect(fn).to.throw("cy.foo() could not be issued because this element is currently animating:\n")

    it "does not throw when threshold has been increased", ->
      @sandbox.stub(@Cypress, "config").withArgs("animationDistanceThreshold").returns(100)

      coords = [{x: 10, y: 20}, {x: 20, y: 30}]

      fn = => @cy.ensureElementIsNotAnimating(null, coords)
      expect(fn).not.to.throw

    it "does not throw when threshold argument has been increased", ->
      coords = [{x: 10, y: 20}, {x: 20, y: 30}]

      fn = => @cy.ensureElementIsNotAnimating(null, coords, 100)
      expect(fn).not.to.throw

    it "does not throw when distance is below threshold", ->
      coords = [{x: 10, y: 20}, {x: 8, y: 18}]

      fn = =>
        @cy.ensureElementIsNotAnimating(null, coords)

      expect(fn).not.to.throw(Error)

  context "#ensureValidPosition", ->
    beforeEach ->
      @allowErrors()

    it "throws when invalid position", ->
      fn = => @cy.ensureValidPosition("foo")

      expect(fn).to.throw('Invalid position argument: \'foo\'. Position may only be topLeft, top, topRight, left, center, right, bottomLeft, bottom, bottomRight.')

    it "does not throws when valid position", ->
      fn = => @cy.ensureValidPosition("topRight")

      expect(fn).to.not.throw

  context "#ensureScrollability", ->
    beforeEach ->
      @allowErrors()

      @add = (el) =>
        $(el).appendTo(@cy.$$("body"))

    it "defaults to current command if not specified", ->
      @cy.$$("body").html("<div>foo</div>")
      win = @cy.state("window")
      @cy.state("current", {
        get: -> "currentCmd"
      })

      fn = => @cy.ensureScrollability(win)

      expect(fn).to.throw('cy.currentCmd() failed because this element is not scrollable:\n\n<window>\n')

    it "does not throw when window and body > window height", ->
      win = @cy.state("window")

      fn = => @cy.ensureScrollability(win, "foo")

      expect(fn).not.to.throw(Error)

    it "throws when window and body > window height", ->
      @cy.$$("body").html("<div>foo</div>")

      win = @cy.state("window")

      fn = => @cy.ensureScrollability(win, "foo")

      expect(fn).to.throw('cy.foo() failed because this element is not scrollable:\n\n<window>\n')

    it "throws when el is not scrollable", ->
      noScroll = @add """
        <div style="height: 100px; overflow: auto;">
          <div>No Scroll</div>
        </div>
        """

      fn = => @cy.ensureScrollability(noScroll, "foo")

      expect(fn).to.throw('cy.foo() failed because this element is not scrollable:\n\n<div style="height: 100px; overflow: auto;">...</div>\n')

    it "throws when el has no overflow", ->
      noOverflow = @add """
        <div style="height: 100px; width: 100px; border: 1px solid green;">
          <div style="height: 150px;">
            No Overflow Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Aenean lacinia bibendum nulla sed consectetur. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor. Etiam porta sem malesuada magna mollis euismod.
          </div>
        </div>
        """

      fn = => @cy.ensureScrollability(noOverflow, "foo")

      expect(fn).to.throw('cy.foo() failed because this element is not scrollable:\n\n<div style="height: 100px; width: 100px; border: 1px solid green;">...</div>\n')

    it "does not throw when vertically scrollable", ->
      vertScrollable = @add """
        <div style="height: 100px; width: 100px; overflow: auto;">
          <div style="height: 150px;">Vertical Scroll</div>
        </div>
      """

      fn = => @cy.ensureScrollability(vertScrollable, "foo")

      expect(fn).not.to.throw(Error)

    it "does not throw when horizontal scrollable", ->
      horizScrollable = @add """
        <div style="height: 100px; width: 100px; overflow: auto; ">
          <div style="height: 150px;">Horizontal Scroll</div>
        </div>
      """

      fn = => @cy.ensureScrollability(horizScrollable, "foo")

      expect(fn).not.to.throw(Error)

    it "does not throw when overflow scroll forced and content larger", ->
      forcedScroll = @add """
        <div style="height: 100px; width: 100px; overflow: scroll; border: 1px solid yellow;">
          <div style="height: 300px; width: 300px;">Forced Scroll</div>
        </div>
      """

      fn = => @cy.ensureScrollability(forcedScroll, "foo")

      expect(fn).not.to.throw(Error)

  ## WE NEED TO ADD SPECS AROUND THE EXACT ERROR MESSAGE TEXT
  ## SINCE WE ARE NOT ACTUALLY TESTING THE EXACT MESSAGE TEXT
  ## IN OUR ACTIONS SPEC (BECAUSE THEY'RE TOO DAMN LONG)
  ##
  ## OR WE SHOULD JUST MOVE TO AN I18N ERROR SYSTEM AND ASSERT
  ## ON A LOOKUP SYSTEM
