{-# LANGUAGE QuasiQuotes, OverloadedStrings, UnicodeSyntax #-}
{-# OPTIONS_GHC -F -pgmF frquotes -fno-warn-missing-signatures #-}
-- VIM :source config.vim

import Kit

import Paper.Keys
import Paper.NbE
import System.IO (hPutStrLn, stderr)

--import qualified MiniTikz.Builder as D -- hiding (node)
--import MiniTikz.Builder (right, below, nodeDistance, oF, dnode, spath, scope)

--import System.Directory (copyFile)

title =  «Names For Free --- Polymorphic Views of Names and Binders»
  -- «Parametric Nested Abstract Syntax» -- Sounds like it's for a representation
  --
  -- «A Classy Kind of Nested Abstract Syntax»
  -- «Implementing Names and Binders with Polymorphism»
-- Ingredients:
-- Classes
-- Polymorphism
-- Nested


authors = [ («Jean-Philippe Bernardy» , «bernardy@chalmers.se» , «Chalmers University of Technology and University of Gothenburg»)
           ,(«Nicolas Pouillard»      , «npou@itu.dk»          , «IT University Copenhagen»)
          ]
abstract = [texFile|abstract|]
keywords = [texFile|keywords|]
_Agda's = «{_Agda}'s»

long = False
short = not long
debug = False

unpackCode =  [haskellFP|
  |unpack :: f (Succ a) → 
  |          (∀ v. v → f (a ▹ v) → r) → r
  |unpack e k = k () e
  |]

apTm =
  [haskellFP|
  |-- Building the following term: λ f x → f x
  |apTm = lam $ λ f → lam $ λ x → var f `App` var x
  |]

canEta =
  [haskellFP|
  |canEta (Lam e) = unpack e $ λ x t → case t of
  |  App e1 (Var y) → y `isOccurenceOf` x &&
  |                    x `freshFor` e1
  |  _ → False
  |canEta _ = False
  |]

-- NP: Trying to factor canEta and canEtaWithSig result
-- in big space between the signature and the code.
-- This is due to the fact haskellP/haskellFP are building
-- paragraphs.
canEtaWithSig =
  [haskellFP|
  |canEta :: Tm Zero → Bool
  |canEta (Lam e) = unpack e $ λ x t → case t of
  |  App e1 (Var y) → y `isOccurenceOf` x &&
  |                    x `freshFor` e1
  |  _ → False
  |canEta _ = False
  |]

{-
Arguments for having v ▹ a instead of a ▹ v

  * If we consider v to be a dummy type then
    this functor ((▹) v) seems more common than
    this functor ((▹) a)
  * Same direction as List.(:), Nompa.(◅), Bound.Var, (∈)
  * If we see this as a morphism (inj :: v -> a) then
    the order is the same

Arguments for keeping the current order

  * Same direction as Γ,x

fmap     :: Functor f     => (a -> b) -> f a -> f b
(=<<)    :: Monad   m     => (a -> m b) -> m a -> m b
traverse :: Applicative f => (a -> f b) -> t a -> f (t b)

isClosed :: Foldable f => f a -> Bool
closed   :: Traversable f => f a -> Maybe (f b)
elem     :: (Foldable t, Eq a) => a -> t a -> Bool
vacuous  :: Functor f => f Void -> f a

On top of Bound:

  type a ▹ v = Var v a

  class v ∈ a where
    inj :: v → a

  instance x ∈ (γ ▹ x) where
    inj = B

  instance (x ∈ γ) ⇒ x ∈ (γ ▹ y) where
    inj = F . inj

  var :: ∀ f v a. (v ∈ a, Monad f) ⇒ v → f a
  var = return . inj

  abs :: ∀ f a. (∀ v. v → f (a ▹ v)) → f (Succ a)
  abs k = k ()

  unpack :: f (Succ a) → (∀ v. v → f (a ▹ v) → r) → r
  unpack e k = k () e

  pack :: Functor tm ⇒ v → tm (a ▹ v) → tm (Succ a)
  pack x = fmap (bimap id (const ()))

  lam :: ∀ a. (∀ v. v → Tm (a ▹ v)) → Tm a
  lam k = Lam (abs k)

  -- Scopes

  abs :: ∀ f a. Monad f ⇒ (∀ v. v → f (a ▹ v)) → Scope () f a
  abs k = toScope . k ()

  lam :: ∀ a. (∀ v. v → Tm (a ▹ v)) → Tm a
  lam k = Lam (abs k)

  class a ⊆ b where
    injMany :: a → b

  instance a ⊆ a where injMany = id

  instance Zero ⊆ a where injMany = magic

  instance (γ ⊆ δ) ⇒ (γ ▹ v) ⊆ (δ ▹ v) where
    injMany = bimap injMany id

  instance (a ⊆ c) ⇒ a ⊆ (c ▹ b) where
    injMany = F . injMany

  wk :: (Functor f, γ ⊆ δ) ⇒ f γ → f δ
  wk = fmap injMany

* Term structure:
    * Monad =>
        * substitution
        * Functor (=> renaming)
        * pure scope manipulation
            * a close term can inhabit any "world": 'vacuous'
    * Traversable =>
        * effectful scope manipulation
            * 'traverse (const Nothing)' is 'closed'
        * Foldable =>
            * fold over the free variables
            * monoidal action on the free-vars
                * 'all (const False)' is 'isClosed'
                * toList
                * elem
* Scope as an abstraction:
    * Once we have an abstraction the concrete definition
      can be changed according to different criterions:
        * efficiency (as the 'Scope' from Bound)
        * simplicity (improve reasoning)

* Nice packing and unpacking of scopes
    * could be better than 'abstract'/'instantiate'
    * higher-order style:
        * ∀ v. v → f (a ▹ v)
        * nice constructions: lam λ x → lam λ y → ...
        * nice unpacking: unpack λ x t → ...
    * nominal style:
        * ∃ v. (v , f (a ▹ v))
        * "fresh x in ..." stands for "case fresh of Fresh x -> ..."
        * fresh x in fresh y in lam x (lam y ...)

-}


  {- NP:
  These throwaway arguments might be a bit worrisome. A more involved
  version would use a type known as Tagged

  data Tagged a b = Tagged b

  Or more specific to our usage

  data Binder v = TheBinder
  -- Iso to Tagged v ()

  unpack :: (∀ v. v → tm (w ▹ v)) →
            (∀ v. Binder v → tm (w ▹ v) → a) → a
  unpack b k = k TheBinder (b TheBinder)

  remove :: Binder v → [a ▹ v] → [a]
  remove _ xs = [x | Old x ← xs]

  ...
  in this case we should also have:
  (∀ v. Binder v → tm (w ▹ v))
  -}


body includeUglyCode = {-slice .-} execWriter $ do -- {{{
  let onlyInCode = when includeUglyCode
  
  onlyInCode $ do 
     [haskellP|
     |{-# LANGUAGE RankNTypes, UnicodeSyntax,
     |    TypeOperators, GADTs, MultiParamTypeClasses,
     |    FlexibleInstances, UndecidableInstances,
     |    IncoherentInstances, ScopedTypeVariables, StandaloneDeriving #-}
     |module PaperCode where
     |import Prelude hiding (elem,any,foldl,foldr)
     |import Control.Monad
     |import Control.Applicative
     |import Data.Foldable
     |import Data.Traversable
     |import Data.List (nub,elemIndex)
     |import Data.Maybe
     |-- import Data.Bifunctor 
     |
     |main :: IO ()
     |main = putStrLn "It works!"
     |]

  {-
  notetodo «unify the terminology names/context/free variables (when the rest is ready)»
     NP: All these three notions names/context/free variables have to
         be used appropriately. I would not "unify" them.
         * A name is either bound or free
         * A context is where a name makes sense
         * A free variable makes reference to somewhere in a term (the Var constructor)
   -}
  section $ «Introduction» `labeled` intro

  p"the line of work where we belong"
   «One of the main application areas of functional programming
    languages such as {_Haskell} is programming language technology. In
    particular, {_Haskell} programmers often find themselves manipulating
    data structures representing some higher-order object languages,
    featuring binders and names.»

  -- NP: not sure about «higher-order object language»

  p"identifying the gap"
   «Yet, the most commonly used representations for names and binders
    yield code which is difficult to read, or error-prone to write
    and maintain. The techniques in question are often referred as
    “nominal”, “de Bruijn indices” and “Higher-Order Abstract
    Syntax (HOAS)”.»

  -- NP: We can make this better.
  p"Nominal pros&cons"
   «In the nominal approach, one typically uses some atomic type to
    represent names. Because a name is simply referred to
    the atom representing it, the nominal style is
    natural. The main issues with this technique are that variables
    must sometimes be renamed in order to avoid name capture (that is,
    if a binder refers to an already used name, variables might end up
    referring to the wrong binder). The need for renaming demands a way
    to generate fresh atoms. This side effect can be resolved with a
    supply for unique atoms or using an abstraction such as a monad
    but is disturbing if one wishes to write functional code.
    Additionally, nominal representations are not canonical. (For instance, two α-equivalent 
    representations of the same term such as {|λx.x|} and {|λy.y|} may 
    be different). Hence special care has to be taken to prevent user code
    to violate the abstraction barrier. Furthermore fresh name
    generation is an observable effect breaking referential transparency
    ({|fresh x in x ≢ fresh x in x|}). For instance a function
    generating fresh names and not properly using them to close
    abstractions becomes impure.»

  -- NP: Note that in a safe interface for binders the supply does not
  -- have to be threaded, only passed downward and can be represented
  -- by a single number that we know all the numbers above are fresh
  -- names.

  p"de Bruijn pros&cons"
   «To avoid the problem of name capture, one can represent names
    canonically, for example by the number of binders, typically λ,
    to cross between an occurrence and its binding site (a de Bruijn index). 
    This has the added benefit of making α-equivalent terms syntactically equal.
    In practice
    however, this representation makes it hard to manipulate terms:
    instead of calling things by name, programmers have to rely on their
    arithmetic abilities, which turns out to be error-prone. As soon as
    one has to deal with more than just a couple open bindings, it becomes
    easy to make mistakes.»

  p"HOAS"
   «Finally, one can use the binders of the host language (in our case {_Haskell})
    to represent binders of the object language. This technique (called HOAS)
    does not suffer
    from name-capture problems nor does it involve arithmetic. However the 
    presence of functions in the term representation mean that it is difficult 
    to manipulate, and it may contain values which do not represent any term.»

  {- NP: the HOAS point of view is that this is more an issue of using Haskell
     function space that is improper for this situation. -}

  p"contribution"
   «The contribution of this paper is a new programming interface for binders, which
    provides the ability to write terms in a natural style close to
    concrete syntax. We can for example build the application function
    of the untyped λ-calculus as follows:»

  commentCode apTm

  q«and we are able to test if a term is eta-contractible using the
    following function:»

  commentCode canEta

  p"contribution continued"
   «All the while, neither do we require a
    name supply, nor is there a risk for name capture.
    Testing terms for α-equivalence remains straightforward and representable
    terms are exactly those intended.
    The cost of this
    achievement is the use of somewhat more involved types for binders,
    and the use of extensions of the {_Haskell} type-system. 
    The new construction is informally described and
    motivated in sec. {ref overview}. In sections {ref contextSec} to {ref scopesSec}
    we present in detail the implementation of the technique as well
    as basic applications.
    Larger applications (normalization using hereditary substitutions, closure conversion and
    CPS transformation) are presented in sec. {ref examples}.
    »

    -- TODO: normalization by evaluation => restore it, put in appendix?

  section $ «Overview» `labeled` overview

  p"flow"
   «In this section we describe our interface, but before doing so we 
    describe a simple implementation which can support this interface.»

  subsection $ «de Bruijn Indices»

  p"de Bruijn indices"
   «{_Citet[debruijnlambda1972]} proposed to represent an occurrence of
    some variable {|x|} by counting the number of binders that one
    has to cross between the occurrence and the binding site of {|x|}.
    A direct implementation of the idea may yield the following
    representation of untyped λ-terms:»

  [haskellFP|
  |data Nat = O | S Nat
  |data TmB where
  |  VarB :: Nat → TmB
  |  AppB :: TmB → TmB → TmB
  |  LamB :: TmB → TmB
  |]

  p"apB"
   «Using this representation, the implementation of the application
    function {|λ f x → f x|} is the following:»

  [haskellFP|
  |apB :: TmB
  |apB = LamB $ LamB $ VarB (S O) `AppB` VarB O
  |]

  p"no static scoping"
   «However, such a direct implementation is cumbersome and naïve. For
    instance it cannot statically distinguish bound and free variables.
    That is, a closed term has the same type as an open term.»

  paragraph «Nested Abstract Syntax»

  p"nested data types"
   «In functional programming languages such as {_Haskell}, it is
    possible to remedy to this situation by using nested data types
    and polymorphic recursion. That is, one parameterizes the type of
    terms by a type that can represent {emph«free»} variables. If the
    parameter is the empty type, terms are closed. If the parameter is
    the unit type, there is at most one free variable, etc.

    This representation is known as Nested Abstract
    Syntax {cite nestedcites}.»

  -- Because the parameter is the type of free-variables,
  -- it does not affect the representation of bound variables
  -- at all.

  -- NP,TODO: 'type', 'class', 'instance', '::', '⇒' are not recognized as keywords
  [haskellFP|
  |data Tm a where
  |  Var :: a → Tm a
  |  App :: Tm a → Tm a → Tm a
  |  Lam :: Tm (Succ a) → Tm a
  |]
  onlyInCode [haskellP|  deriving (Show)|]

  p"the type of Lam"
   «The recursive case {|Lam|} changes the type parameter, increasing
    its cardinality by one, since the body can refer to one more
    variable. Anticipating the amendments we propose, we define the
    type {|Succ a|} as a proper sum of {|a|} and the unit type {|()|}
    instead of {|Maybe a|} as customary. Because the sum is used in an
    asymmetric fashion (the left-hand-side corresponds to variables
    bound earlier and the right-hand-side to the freshly bound one),
    we give a special definition of sum written {|▹|}, whose syntax
    reflects the intended semantics.»

  [haskellFP|
  |type Succ a = a ▹ ()
  |
  |data a ▹ v = Old a | New v
  |
  |bimap :: (a → a') → (v → v') →
  |         (a ▹ v) → (a' ▹ v')
  |bimap f _ (Old x) = Old (f x)
  |bimap _ g (New x) = New (g x)
  |
  |untag :: a ▹ a → a
  |untag (Old x) = x
  |untag (New x) = x
  |]

--  |instance Bifunctor (▹) where
  onlyInCode [haskellP|deriving instance (Show a, Show b) ⇒ Show (a ▹ b)|]

  p"apNested example"
   «Using the {|Tm|} representation, the implementation of the application
    function {|λ f x → f x|} is the following:»

  [haskellFP|
  |apNested :: Tm Zero
  |apNested = Lam $ Lam $ Var (Old $ New ())
  |                 `App` Var (New ())
  |]

  p"the type of apNested"
   «As promised, the type is explicit about {|apNested|} being a closed
    term: this is ensured by using the empty type {|Zero|} as an
    argument to {|Tm|}.»

  [haskellFP|
  |data Zero -- no constructors
  |]

  p"polymorphic terms are closed"
   «In passing, we remark that another type which faithfully captures
    closed terms is {|∀ a. Tm a|} --- literally: the type of terms which
    are meaningful in any context.
    Indeed, because {|a|} is universally quantified, there is no way
    to construct an inhabitant of it; therefore one cannot possibly refer to any
    free variable. In particular one can instantiate {|a|} to be the
    type {|Zero|}.»

  p"de Bruijn drawback"
   «However the main drawback of using de Bruijn indices remains: one must still
    count the number of binders between the declaration of a variable and its occurrences.»

  subsection «Referring to Bound Variables by Name»

  p"flow"
   «To address the issues just touched upon, we
    propose to build λ-abstractions with a function called {|lam|}. What
    matters the most is its type:»

  [haskellFP|
  |lam :: (∀ v. v → Tm (a ▹ v)) → Tm a
  |lam f = Lam (f ())
  |]

    {-
  [haskellFP|
  |data Tm a where
  |  Var :: a → Tm a
  |  App :: Tm a → Tm a → Tm a
  |  Lam :: (∀ v. v → Tm (a ▹ v)) → Tm a
  |]
  -}

  p"explain ∀ v, v →"
   «That is, instead of adding a concrete unique type (namely {|()|}) in
    the recursive parameter of {|Tm|}, we quantify universally over a
    type variable {|v|} and add this type variable to the type of free
    variables. The body of the lambda-abstraction receives an arbitrary value of type {|v|},
    to be used at occurrences of the variable bound by {|lam|}.»

  -- NP: "provide the sub-term" is one side of the coin, the other side
  -- would be to say that a name abstraction receives a value of type v
  -- to be....

  p"const"
   «The application function is then built as follows:»

  [haskellFP|
  |apTm_ :: Tm Zero
  |apTm_ = lam $ λ f → lam $ λ x → Var (Old (New f))
  |                  ☐        `App` Var (New x)
  |]

  p"still the same elephant"
   «By unfolding the definition of {|lam|} in {|apTm_|} one recovers
    the definition of {|apNested|}.»

  paragraph «Safety»

  p"host bindings are the spec"
   «Using our approach, the binding structure, which can be identified as
    the {emph«specification»}, is written using the host language binders.

    However at variable occurrences, de Bruijn indices are still present
    in the form of the constructors {|New|} and {|Old|}, and are
    purely part of the {emph«implementation»}.»

  p"type-checking the number of Old..."
   «The type-checker then makes sure that the implementation matches the specification:
    for example if one now makes a mistake and forgets one {|Old|} when entering the
    term, the {_Haskell} type system rejects the definition.»

  commentCode [haskellFP|
  |oops_ = lam $ λ f → lam $ λ x → Var (New f)
  |                  ☐        `App` Var (New x)
  |-- Couldn't match expected type `v1'
  |--             with actual type `v'
  |]

  p"no mistakes at all"
   «In fact, if all variables are introduced with the {|lam|} combinator
    the possibility of making a mistake in the
    {emph«implementation»} is nonexistent, if we ignore obviously diverging terms.
    Indeed, because the type {|v|} corresponding to a bound variable is
    universally quantified, the only way to construct a value of its
    type is to use the variable bound by {|lam|}. (In {_Haskell}
    one can use a diverging program; however one has to make a conscious decision 
    to produce a value of such an obviously empty type.)»

  p"unicity of injections"
   «In general, in a closed context, if one considers the
    expression {|Var ((Old)ⁿ (New x))|}, only one possible value
    of {|n|} is admissible. Indeed, anywhere in the formation of a term
    using {|lam|}, the type of variables is {|a = a₀ ▹ v₀ ▹ v₁ ▹ ⋯ ▹ vₙ|}
    where {|v₀|}, {|v₁|}, … , {|vₙ|} are all distinct and universally
    quantified, and none of them occurs as part of {|a₀|}. Hence, there
    is only one injection function from a given {|vᵢ|} to {|a|}.»

  paragraph «Auto-Inject»

  p"auto-inject"
   «Knowing that the injection functions are uniquely determined by
    their type, one may wish to infer them mechanically. Thanks 
    the powerful instance search mechanism implemented in GHC, this
    is feasible. To this effect, we define a class {|v ∈ a|} capturing that {|v|}
    occurs as part of a context {|a|}:»

  [haskellFP|
  |class v ∈ a where
  |  inj :: v → a
  |]

  p"var"
   «We can then wrap the injection function and {|Var|} in a convenient
    package:»

  commentCode [haskellFP|
  |var :: ∀ v a. (v ∈ a) ⇒ v → Tm a
  |var = Var . inj
  |]

  p"apTm"
   «and the application function can be conveniently written:»

  apTm

  p"more intuitions"
   «In a nutshell, our de Bruijn indices are typed with the context
    where they are valid. If that context is sufficiently polymorphic,
    they can not be mistakenly used in a wrong context. Another
    intuition is that {|New|} and {|Old|} are building proofs
    of “context membership”. Thus, when a de Bruijn index is given a maximally polymorphic context,
    it is similar to a well-scoped name.»

  p"flow to next section"
   «So far, we have seen that by taking advantage of polymorphism, 
    our interface allows to construct
    terms with de Bruijn indices, combined with the safety and
    convenience of named variables. In the next section we show how
    to use the same idea to provide the same advantages for the analysis
    and manipulation of terms.»

  subsection «Referring to Free Variables by Name»

  p"unpack"
   «Often, one wants to be able to check if an
    occurrence of a variable is a reference to some previously bound
    variable. With de Bruijn indices, one must (yet again) count the
    number of binders traversed between the variable bindings and
    its potential occurrences --- an error prone task. Here as well,
    we can take advantage of polymorphism to ensure that no mistake
    happens. We provide a combinator {|unpack|}, which hides the 
    type of the newly bound variables (the type {|()|}) as an existentially
    quantified type {|v|}. The combinator {|unpack|} takes a binding
    structure (of type {|Tm (Succ a)|}) and gives a pair of
    a value {|x|} of type {|v|} and a
    sub-term of type {|Tm (a ▹ v)|}. Here we represent the existential using
    continuation-passing style instead of a data-type, as it appears more convenient to use
    this way. 
    Because this combinator is not specific to our
    type {|Tm|} we generalize it to any type constructor {|f|}:»

  --    (See section TODO FORWARD REFERENCE for another solution
  --  based on view patterns.) 

  unpackCode

  -- NP: removed “occurs only positively in∼{|f|} (or∼{|Tm|})”
  -- since it is wrong if you can pick any f. Either we stick
  -- a Functor f instance or argue that this because of the lack
  -- of information of v.
  p"why unpack works"
   «Because {|v|} is existentially bound, {|x|} can never be used in a
    computation. It only acts as a reference to a variable in a context,
    in a way which is only accessible to the type-checker.

    For instance, when facing a term {|t|} of type
    {|Tm (a ▹ v₀ ▹ v₁ ▹ v)|}, {|x|} refers to the last introduced free
    variable in {|t|}.

    Using {|unpack|}, one can write a function which can recognize an
    eta-contractible term as follows: (Recall that an a eta-contractible
    term has the form {|λ x → e x|}, where {|x|} does not occur free
    in {|e|}.)»

  canEtaWithSig

  {-
   NP: Issue with unpack: it becomes hard to tell if a recursive function is
       total. Example:

       foo :: Tm a → ()
       foo (Lam e) = unpack e $ λ x t → foo t
       foo _       = ()

   As long as unpack is that simple, this might be one of those situations
   where we want to inline unpack. This new code is then termination checked
   and kept as the running program (let's not make the same mistakes as Coq).
  -}

  p"canEta"
   «In the above example, the two functions {|isOccurenceOf|}
    and {|freshFor|} use the {|inj|} function to lift {|x|} to
    a reference in the right context before comparing it to the
    occurrences. The calls to these functions do not get more complicated
    in the presence of multiple binders. For example, the code which
    recognizes the pattern {|λ x y → e x|} is as follows:»

  [haskellFP|
  |recognize :: Tm Zero → Bool
  |recognize t0 = case t0 of
  |    Lam f → unpack f $ λ x t1 → case t1 of
  |      Lam g → unpack g $ λ y t2 → case t2 of
  |        App e1 (Var y) → y `isOccurenceOf` x &&
  |                          x `freshFor` e1
  |        _ → False
  |      _ → False
  |    _ → False
  |]

  p"slogan"
   «Again, even though variables are represented by mere indices, the use
    of polymorphism allows the user to refer to them by name, using the instance
    search mechanism to fill in the details of implementation.»

  {-
  subsection $ «Packing and Unpacking Binders»

  p""«In order to examine the content of a term with another bound variable,
      one must apply a concrete argument to the function of type {|∀ v. v → Term (a ▹ v)|}.
      The type of that argument can be chosen freely --- that freedom is sometimes useful
      to write idiomatic code. One choice is
      unit type and its single inhabitant {|()|}. However this choice locally reverts to using
      plain Nested Abstract Syntax, and it is often advisable to chose a more specific type.

      In particular, a canonical choice is a maximally polymorphic type. This is the choice
      is made by using the {|unpack|} combinator.
      »
      -- While I agree that using the unit type everywhere reverts to using
      -- Nested Abstract Syntax, the one time use of () is I think
      -- a good style since there is nothing to confuse about free variables
      -- since there is only one.

      -- In a total language, unpack would be
      -- defined as unpack b k = k () (b ()). Which essentially turns
      -- unpack b λ x t → E into let { x = () ; t = b () } in E.
      --
      -- However, a real implementation of the technique would need something like the
      -- nabla combinator, where unpack would essentially be provided natively.
      --
      -- I still like the pack/unpack mode a lot it shines well when multiple
      -- binders are opened at once.
  commentCode unpackCode

  {-
  [haskellP|
  |unpack binder k = k fresh (binder fresh)
  |  where fresh = ()
  |]
  -}

  p""«The continuation {|k|}
  is oblivious to 
  the monomorphic type used by the implementation of {|fresh|}: this is expressed by universally quantifing {|v|} in the type of the continuation {|k|}.

  In fact, thanks to parametricity, and because {|v|} occurs only positively in the arguments of {|k|},
  it is guaranteed that {|k|} cannot observe the implementation of {|fresh|} at all (except for the escape hatch of {|seq|}).
  In particular one could even define {|fresh = undefined|}, and the code would continue to work.»

  p""«As we have seen in previous examples, the {|unpack|} combinator gives the possibility
  to refer to a free variable by name, enabling for example to compare a variable
  occurrence with a free variable. Essentially, it offers a nominal interface to free variables:
  even though the running code will use de Bruijn indices, the programmer sees names; and
  the correspondence is enforced by the type system.
  »
  -}

  paragraph «Pack»

  p"pack"
   «It is easy to invert the job
    of {|unpack|}. Indeed, given a value {|x|} of type {|v|} and a term
    of type {|Tm (a ▹ v)|} one can reconstruct a binder as follows: »

  [haskellFP|
  |pack :: Functor tm ⇒ v → tm (a ▹ v) → tm (Succ a)
  |pack x = fmap (bimap id (const ()))
  |]
  q«(The {|Functor|} constraint is harmless, as we will see in sec. {ref termStructure}.)

    As we can see, the value {|x|} is not used by pack. However it
    statically helps as a specification of the user intention: it makes sure
    the programmer relies on host-level variable names, and not indices.»

  -- TODO
  q«A production-quality version of {|pack|} would allow to bind any 
    free variable. Writing the constraint {|Insert v a b|} to mean 
    that by removing the variable {|v|} 
    from the context {|b|} one obtains {|a|}, then a generic {|pack|} would have the 
    following type:»
  [haskellFP|
  |packGen :: ∀ f v a b w. (Functor f, Insert v a b) ⇒
  |           v → f b → (w → f (a ▹ w))
  |]
  q«The implementation of {|packGen|} and {|Insert|} is a straightforward extension of {|inj|} and {|(∈)|},
     but it does not fit here, so we defer it to the appendix.»

  p"lamP"
   «In sum, the {|pack|} combinator makes it possible to give a nominal-style
    interface to binders. For example an alternative way to build
    the {|Lam|} constructor is the following:»

  [haskellFP|
  |lamP :: v → Tm (a ▹ v) → Tm a
  |lamP x t = Lam (pack x t)
  |]

  -- section $ «»

  section $ «Contexts» `labeled` contextSec

  p"flow" «Having introduced our interface informally, we now begin a
           systematic description of is realization and the concepts it builds upon.»
  

  p"flow, ▹"
   «We have seen that the type of free variables essentially describes
    the context where they are meaningful. A context can either be
    empty (and we represent it by the type {|Zero|}) or not (which we
    can represent by the type {|a ▹ v|}).»

  p"explain remove"
   «An important function of the {|v|} type variable is to make sure
    programmers refer to the variable they intend to. For example,
    consider the following function, which takes a list of (free)
    variables and removes one of them from the list. It takes a list
    of variables in the context {|a ▹ v|} and returns a list in the
    context {|a|}. For extra safety, it also takes the name of the
    variable being removed, which is used only for type-checking
    purposes.»

  -- (As for {|pack|}, {|remove|} can be generalized to use the {|Insert|})... However we have not seen ∈ yet, so this makes little sense.
  [haskellFP|
  |remove :: v → [a ▹ v] → [a]
  |remove _ xs = [x | Old x ← xs]
  |]

  p"explain freeVars"
   «The function which computes the list of occurrences of free variables in a term can
    be directly transcribed from its nominal-style definition, thanks
    to the {|unpack|} combinator.»

  [haskellFP|
  |freeVars :: Tm a → [a]
  |freeVars (Var x) = [x]
  |freeVars (Lam b) = unpack b $ λ x t →
  |   remove x (freeVars t)
  |freeVars (App f a) = freeVars f ++ freeVars a
  |]

  subsection $ «Names Are Polymorphic Indices»


  p"Eq Zero"
   «Checking whether two names are equal or not is necessary to implement a large 
    class of term manipulation functions.
    To implement comparison between names, we provide the following two {|Eq|} instances.
    First, the {|Zero|} type is vacuously equipped with equality:»

  [haskellFP|
  |instance Eq Zero where
  |  (==) = magic
  |
  |magic :: Zero → a
  |magic _ = error "impossible"
  |]

  p""
   «Second, if two indices refer to the first variable they are equal;
    otherwise we recurse. We stress that this equality inspects only the
    {emph«indices»}, not the values contained in the type. For
    example {|New 0 == New 1|} is {|True|}:»

  -- NP: TODO nbsp are messed up by the highlighter

  {-
  instance (Eq a, Eq v) ⇒ Eq (a ▹ v) where
    New x == New y = x == y
    Old x == Old y = x == y
    _     == _     = False

  instance Eq (Binder a) where
    _ == _ = True
  -}

  [haskellFP|
  |instance Eq a ⇒ Eq (a ▹ v) where
  |  New _ == New _ = True
  |  Old x == Old y = x == y
  |  _     == _     = False
  |]
  q«
    Comparing naked de Bruijn indices for equality is an error prone operation, 
    because one index might be valid in
    a context different from the other, and thus an arbitrary adjustment might be required.
    With Nested Abstract Syntax, the situation improves: by requiring equality to be 
    performed between indices of the same type, a whole class of errors are prevented by
    type-checking. Some mistakes are possible though: given a index of type {|a ▹ () ▹ ()|},
    a swap the last two variables might be the right thing to do, but one cannot decide if it is so 
    from the types only.
    By making the contexts fully
    polymorphic as we propose, no mistake is possible. 
    Hence the slogan: names are polymorphic indices.»

  q«Consequently, the derived equality instance of {|Tm|} gives
    α-equality, and is guaranteed safe in fully-polymorphic contexts.»

  onlyInCode [haskellFP|
  |deriving instance Eq a ⇒ Eq (Tm a)
  |]

  subsection «Membership»
  q«Given the above representation of contexts, we can implement
    the relation of context membership by a type class {|∈|}, whose
    sole method performs the injection from a member of the context to
    the full context. The relation is defined by two inference rules,
    corresponding to finding the variable in the first position of the
    context, or further away in it, with the necessary injections:»

  [haskellFP|
  |instance v ∈ (a ▹ v) where
  |  inj = New
  |
  |instance (v ∈ a) ⇒ v ∈ (a ▹ v') where
  |  inj = Old . inj
  |]

  p"incoherent instances"
   «The cognoscenti will recognize the two above instances as
    {emph«incoherent»}, that is, if {|v|} and {|v'|} were instantiated
    to the same type, both instances would apply, but the injections would be different. Fortunately,
    this incoherence never triggers as long as one keeps the contexts
    maximally polymorphic contexts: {|v|} and {|v'|} will always be
    different.»

  -- NP: maybe mention the fact that GHC let us do that

  p"inj enables var"
   «We have seen before that the overloading of the {|inj|} function
    in the type class {|∈|} allows to automatically convert a type-level
    reference to a term into a properly tagged de Bruijn index, namely
    the function {|var|}.»

  p"explain isOccurenceOf"
   «Conversely, one can implement occurrence-check by combining  {|inj|} with {|(==)|}:
    one first lifts the bound variable to the context of the chosen occurrence and
    then tests for equality.»

  [haskellFP|
  |isOccurenceOf :: (Eq a, v ∈ a) ⇒ a → v → Bool
  |x `isOccurenceOf` y = x == inj y
  |]

  p"occursIn"
   «One can test if a variable is fresh for a given term as follows:»
  -- We should not use Data.Foldable.elem here: we have not seen the
  -- Foldable instance yet.  At this point the cosmetic benefit is
  -- outweighed by the cost of the dangling (future) references.
  [haskellFP|
  |freshFor :: (Eq a, v ∈ a) ⇒ v → Tm a → Bool
  |x `freshFor` t = not (inj x `elem` freeVars t)
  |]


  subsection «Inclusion»
  p"context inclusion, ⊆"
   «Another useful relation is context inclusion between contexts, which we also
    represent by a type class, named {|⊆|}. The sole method of the
    typeclass is again an injection, from the small context to the
    bigger one. The main application of {|⊆|} is in term weakening,
    presented at the end of sec. {ref functorSec}.»
  [haskellFP|
  |class a ⊆ b where
  |  injMany :: a → b
  |]

  p"⊆ instances"
   «This time we have four instances: inclusion is reflexive; the empty
    context is the smallest one; adding a variable makes the context
    larger; and variable append {|(▹ v)|} is monotonic for inclusion.»

  [haskellFP|
  |instance a ⊆ a where injMany = id
  |
  |instance Zero ⊆ a where injMany = magic
  |
  |instance (a ⊆ b) ⇒ a ⊆ (b ▹ v) where
  |  injMany = Old . injMany
  |
  |instance (a ⊆ b) ⇒ (a ▹ v) ⊆ (b ▹ v) where
  |  injMany = bimap injMany id
  |]

  p"(▹) functoriality"
   «This last case uses the fact that {|(▹)|} is functorial in its first argument.»


  -- NP
  section $ «Term Structure» `labeled` termStructure

  p"motivation"
   «It is well-known that every term representation parameterized
    on the type of free variables should exhibit monadic structure,
    with substitution corresponding to the binding operator {cite
    nestedcites}. That is, a {|Monad tm|} constraint means that a that
    a term representation {|tm|} is stable under substitution. In
    this section we review this structure, as well as other standard
    related structures on terms. These structures are perhaps easier
    to implement directly on a concrete term representation, rather
    than our interface. However, we give an implementation solely based
    on it, to demonstrate that it is complete with respect to these
    structures. By doing so, we also illustrate how to work with our
    interface in practice.»

  subsection $ «Renaming and Functors» `labeled` functorSec

  p"intro functor"
   «The first, perhaps simplest, property of terms is that free
    variables can be renamed. This property is captured by
    the {|Functor|} structure.»

  p"describe Functor Tm"
   «The “renaming” to apply is given as a function {|f|} from {|a|}
    to {|b|} where {|a|} is the type of free variables of the input
    term ({|Tm a|}) and {|b|} is the type of free variables of the
    “renamed” term ({|Tm b|}). While the function {|f|} should be injective
    to be considered a renaming, the functor instance
    works well for any function {|f|}. The renaming operation then
    simply preserves the structure of the input term. At occurrence
    sites it uses {|f|} to rename free variables. At binding sites,
    {|f|} is upgraded from {|(a → b)|} to {|(a ▹ v → b ▹ v)|} using
    the functoriality of {|(▹ v)|} with {|bimap f id|}. Adapting the
    function {|f|} is necessary to protect the bound name from being
    altered by {|f|}, and thanks to our use of polymorphism, the
    type-checker ensures that we make no mistake in doing so.»

  [haskellFP|
  |instance Functor Tm where
  |  fmap f (Var x)   = Var (f x)
  |  fmap f (Lam b)   = unpack b $ λ x t →
  |                       lamP x $ fmap (bimap f id) t
  |  fmap f (App t u) = App (fmap f t) (fmap f u)
  |]

  p"functor laws"
   «As usual satisfying functor laws implies that the structure is
    preserved by the functor action ({|fmap|}). The type for terms being
    a functor therefore means that applying a renaming is going to only
    affect the free variables and leave the structure untouched. That is,
    whatever the function {|f|} is doing, the bound names are not
    changing. The {|Functor|} laws are the following:»

  doComment
    [haskellFP|
    |fmap id ≡ id
    |fmap (f . g) ≡ fmap f . fmap g
    |]

  p"reading the laws"
   «In terms of renaming, they mean that the identity function corresponds
    to not renaming anything
    and compositions of renaming functions corresponds to two sequential
    renaming operations.»

  q«Assuming only a functor structure, it is possible to write useful
    functions on terms which involve only renaming. A couple of examples
    follow.»

  q«First, let us assume an equality test on free variables. 
    We can then write a function
    {|rename (x,y) t|} which replaces free occurrences of {|x|} in {|t|}
    by {|y|} and {|swap (x,y) t|} which exchanges free occurrences
    of {|x|} and {|y|} in {|t|}.»

  [haskellFP|
  |rename0 :: Eq a ⇒ (a, a) → a → a
  |rename0 (x,y) z | z == x    = y
  |                | otherwise = z
  |
  |rename :: (Functor f, Eq a) ⇒ (a, a) → f a → f a
  |rename = fmap . rename0
  |]

  [haskellP|
  |swap0 :: Eq a ⇒ (a, a) → a → a
  |swap0 (x,y) z | z == y    = x
  |              | z == x    = y
  |              | otherwise = z
  |
  |swap :: (Functor f, Eq a) ⇒ (a, a) → f a → f a
  |swap = fmap . swap0
  |]

    {-
  -- "proofs", appendix, long version, useless...
  -- using: fmap f (Lam g) = Lam (fmap (bimap f id) . g)
  doComment
    [haskellFP|
    |fmap id (Var x)
    |  = Var (id x) = Var x
    |
    |fmap id (Lam g)
    |  = Lam (fmap (bimap id id) . g)
    |  = Lam (fmap id . g)
    |  = Lam (id . g)
    |  = Lam g
    |
    |fmap (f . g) (Var x)
    |  = Var ((f . g) x)
    |  = Var (f (g x))
    |  = fmap f (Var (g x))
    |  = fmap f (fmap g (Var x))
    |
    |fmap (f . g) (Lam h)
    |  = Lam (fmap (bimap (f . g) id) . h)
    |  = Lam (fmap (bimap f id . bimap g id) . h)
    |  = Lam (fmap (bimap f id) . fmap (bimap g id) . h)
    |  = fmap f (Lam (fmap (bimap g id) . h))
    |  = fmap f (fmap g (Lam h))
    |]
  -}

  p"auto-weakening"
   «Second, let us assume two arguments {|a|} and {|b|} related by the
    type class {|⊆|}. Thus we have {|injMany|} of type {|a → b|}, which
    can be seen as a renaming of free variables via the functorial
    structure of terms. By applying {|fmap|} to it, one obtains
    an arbitrary weakening from the context {|a|} to the bigger
    context {|b|}.»

  [haskellFP|
  |wk :: (Functor f, a ⊆ b) ⇒ f a → f b
  |wk = fmap injMany
  |]

  q«Again, this arbitrary weakening function relieves the programmer from
    tediously counting indices and constructing an appropriate renaming function. We
    demonstrate this feature in sec. {ref examples}.»

  subsection $ «Substitution and Monads» `labeled` monadSec

  q«Another useful property of terms is that they can be substituted for free variables in
    other terms. This property is captured algebraically by asserting
    that terms form a {|Monad|}, where {|return|} is the variable
    constructor and {|>>=|} acts as parallel substitution. Indeed, one
    can see a substitution from a context {|a|} to a context {|b|} as
    mapping from {|a|} to {|Tm b|}, (technically a morphism in the associated Kleisli
    category) and {|(>>=)|} applies a substitution everywhere in a term.»

  q«The definition of the {|Monad|} instance is straightforward for
    variable and application, and we isolate the handling of binders in
    the {|(>>>=)|} function.»

  [haskellFP|
  |instance Monad Tm where
  |  return = Var
  |  Var x   >>= θ = θ x
  |  Lam s   >>= θ = Lam (s >>>= θ)
  |  App t u >>= θ = App (t >>= θ) (u >>= θ)
  |]

  q«At binding sites, one needs to lift the substitution so that it does not
    act on the newly bound variables, a behavior isolated in the helper {|>>>=|}. As for the {|Functor|} instance,
    the type system guarantees that no mistake is made. Perhaps
    noteworthy is that this operation is independent of the concrete
    term structure: we only “rename” with {|fmap|} and inject variables
    with {|return|}.»

  -- TODO we under use the monadic structure of tm∘(▹v)
  [haskellFP|
  |liftSubst :: (Functor tm, Monad tm) ⇒
  |          v → (a → tm b) → (a ▹ v) → tm (b ▹ v)
  |liftSubst _ θ (Old x) = fmap Old (θ x)
  |liftSubst _ θ (New x) = return (New x)
  |]

{-
The job of >>>= is basically:
(>>>=) :: (a → tm b) → s tm a → s tm b
introduce θ : a → tm b
          x : s tm a

apply θ inside x (using appropriate higher-order fmap) and get
          y : s tm (tm b)

then the crucial point is to lift out tm:

          z : s (tm ∘ tm) b

then apply join inside the structure (using the other higher-order fmap)

          w : s tm b
-}

  q«Substitution under a binder {|(>>>=)|} is then the wrapping
    of {|liftSubst|} between {|unpack|} and {|pack|}. It is uniform as
    well, and thus can be reused for every structure with binders.»

  -- TODO NP: SuccScope/UnivScope/... are monad transformers

  [haskellFP|
  |(>>>=) :: (Functor tm, Monad tm) ⇒
  |          tm (Succ a) → (a → tm b) → tm (Succ b)
  |s >>>= θ = unpack s $ λ x t →
  |             pack x (t >>= liftSubst x θ)
  |]

  p"laws"
   «For terms, the meaning of the monad laws can be interpreted as follows.
    The associativity law ensures that applying a composition of
    substitutions is equivalent to sequentially applying them, while the
    identity laws ensure that variables act indeed as such.»


  q«We can write useful functions for terms based only on the {|Monad|} structure. 
    For example, given the membership ({|∈|}), one can provide the a
    generic combinator to reference to a variable within any term structure:»

  [haskellFP|
  |var :: (Monad tm, v ∈ a) ⇒ v → tm a
  |var = return . inj
  |]

  q«One can also substitute an arbitrary variable:»

  [haskellFP|
  |substitute :: (Monad tm, Eq a, v ∈ a) ⇒
  |              v → tm a → tm a → tm a
  |substitute x t u = u >>= λ y →
  |     if y `isOccurenceOf` x then t else return y
  |]

  -- NP: I changed the names again, I agree that this often the function
  -- we should be using, however this is not what is expected to correspond
  -- to one substitution as in t[x≔u]
  q«One might however also want to remove the substituted
    variable from the context while performing the substitution:»
  [haskellFP|
  |substituteOut :: Monad tm ⇒
  |                 v → tm a → tm (a ▹ v) → tm a
  |substituteOut x t u = u >>= λ y → case y of
  |     New _ → t
  |     Old x → return x
  |]


  {-
  lift Var x = Var x
  lift Var (Old x) = wk (Var x) = fmap injMany (Var x) = Var (injMany x) =?= Var (Old x)
  lift Var (New  x) = var x = Var (inj x) =?= Var (New x)
  -}

  {-
  lift return x = return x
  lift return (Old x) = fmap Old (return x) = return (Old x)
  lift return (New  x) = return (New x)
  -}

  subsection «Traversable»

  p"explain traverse"
   «Functors enable to apply any pure function {|f :: a → b|} to the
    elements of a structure to get a new structure holding the images
    of {|f|}. Traversable structures enable to apply an effectful
    function {|f :: a → m b|} where {|m|} can be any {|Applicative|}
    functor. An {|Applicative|} functor is strictly more powerful
    than a {|Functor|} and strictly less powerful than a {|Monad|}.
    Any {|Monad|} is an {|Applicative|} and any {|Applicative|}
    is a {|Functor|}. To be traversed a structure only needs
    an applicative and therefore support monadic actions
    directly {cite[mcbrideapplicative2007]}.»

  [haskellFP|
  |instance Traversable Tm where
  |  traverse f (Var x)   = Var <$> f x
  |  traverse f (App t u) =
  |    App <$> traverse f t <*> traverse f u
  |  traverse f (Lam t)   =
  |    unpack t $ λ x b →
  |      lamP x <$> traverse (bitraverse f pure) b
  |]

  p"explain bitraverse"
   «In order to traverse name abstractions, indices need to be traversed
    as well. The type {|(▹)|} is a bi-functor and is bi-traversable.
    The function {|bitraverse|} is given two effectful functions, one for
    each case:»

  [haskellFP|
  |bitraverse :: Functor f ⇒ (a     → f a')
  |                        → (b     → f b')
  |                        → (a ▹ b → f (a' ▹ b'))
  |bitraverse f _ (Old x) = Old <$> f x
  |bitraverse _ g (New x) = New <$> g x
  |]

  q«An example of a useful effect to apply is throwing an exception,
    implemented for example as the {|Maybe|} monad. If a term has no
    free variable, then it can be converted from the type {|Tm a|}
    to {|Tm Zero|} (or equivalently {|∀ b. Tm b|}), but this requires a dynamic
    check. It may seem like a complicated implementation is necessary,
    but in fact it is a direct application of the {|traverse|}
    function.»

  [haskellFP|
  |closed :: Traversable tm ⇒ tm a → Maybe (tm b)
  |closed = traverse (const Nothing)
  |]

  p"freeVars is toList"
   «Thanks to terms being an instance of {|Traversable|} they are
    also {|Foldable|} meaning that we can combine all the elements of
    the structure (i.e. the occurrences of free variables in the term)
    using any {|Monoid|}. One particular monoid is the free monoid of
    lists. Consequently, {|Data.Foldable.toList|} is computing the
    free variables of a term and {|Data.Foldable.elem|} can be used to
    build {|freshFor|}:»

  [haskellFP|
  |freeVars' :: Tm a → [a]
  |freeVars' = toList
  |
  |freshFor' :: (Eq a, v ∈ a) ⇒ v → Tm a → Bool
  |x `freshFor'` t = not (inj x `elem` t)
  |]

{- NP: cut off-topic?
  -- TODO flow
  p""
   «New the function {|size|} takes as an argument how to assign
    a size to each free variable (the type {|a|}). An alternative
    presentation would instead require a term whose variables are
    directly of type {|Size|}. One can recover this alternative by
    passing the identity function as first argument. However the other
    way around requires to traverse the term.»

  -- TODO maybe too much
  [haskellFP|
  |type S f b = forall a. (a -> b) -> f a -> b
  |type T f b = f b -> b
  |
  |to :: S f b -> T f b
  |to s = s id
  |
  |from :: Functor f =>  T f b -> S f b
  |from t f = t . fmap f
  |]

could we get some fusion?

s f . fmap g
==
s (f . g)

-}

  section $ «Scopes» `labeled` scopesSec

  p"flow"«
  Armed with an intuitive understanding of safe interfaces to manipulate de Bruijn indices, 
  and the knowledge that one can abstract over any 
  substitutive structure by using standard type-classes, we can recapitulate and succinctly describe
  the essence of our constructions.»

  notetodo «NP: what about using a figure to collect some of the most crucial definitions? JP: good idea if there is space»
  q«In Nested Abstract Syntax, a binder introducing one variable in scope, for an arbitrary term structure {|tm|}
    is represented as follows:»
  [haskellFP|
  |type SuccScope tm a = tm (Succ a)
  |]

  q«In essence, we propose two new, dual representations of binders,
                                             one based on universal
  quantification, the other one based on existential quantification.»

  onlyInCode [haskellFP|
  |type UnivScope f a = ∀ v. v → f (a ▹ v)
  |]
  commentCode [haskellFP|
  |type UnivScope  tm a = ∀ v.  v → tm (a ▹ v)
  |type ExistScope tm a = ∃ v. (v ,  tm (a ▹ v))
  |]
  q«The above syntax for existentials is not supported in {_Haskell}, so we must use
    one of the lightweight encodings available. In the absence of view patterns,   
    a CPS encoding is
    convenient for programming (so we used this so far),
    but a datatype representation is more convenient when dealing with scopes only:»

  [haskellFP|
  |data ExistScope tm a where
  |  E :: v → tm (a ▹ v) → ExistScope tm a
  |] 

  q«As we have observed on a number of examples, these representations
    are dual from a usage perspective: the universal-based representation
    allows safe the construction of terms, while the existential-based representation 
    allows safe analysis of terms.
    Strictly speaking, safety holds only if one disregards non-termination and {|seq|}, 
    but because the
    values of type {|v|} are never used for computation, mistakenly using a
    diverging term in place of a witness
    of variable name is far-fetched.»

  q«For the above reason, we do not commit to either side, and use the
    suitable representation on a case-by-case basis. This flexibility
    is possible because these scope representations ({|SuccScope|},
    {|UnivScope|} and {|ExistScope|}) are isomorphic. In the following
    we exhibit the conversion functions between {|SuccScope|} one side
    and either {|UnivScope|} or {|ExistScope|}) on the other. We then
    prove that they form isomorphisms, assuming an idealized {_Haskell}
    lacking non-termination and {|seq|}.»

  -- NP: should we cite “Fast and loose reasoning is morally correct”

  subsection «{|UnivScope tm a ≅ SuccScope tm a|}»
  p"conversions"
   «The conversion functions witnessing the isomorphism are the following.»
  -- if you remove this newpage put back [haskellFP|
  newpage
  [haskellP|
  |succToUniv :: Functor tm ⇒
  |              SuccScope tm a → UnivScope tm a
  |succToUniv t = λ x → bimap id (const x) <$> t
  |]
  [haskellP|
  |univToSucc :: UnivScope tm a → SuccScope tm a
  |univToSucc f = f ()
  |]

  q«The {|univToSucc|} function has not been given a name in the
    previous sections, but was implicitly used in the definition
    of {|lam|}. This is the first occurrence of the {|succToUniv|}
    function.»

  q«We prove first that {|UnivScope|} is a proper representation
    of {|SuccScope|}, that is {|univToSucc . succToUniv ≡ id|}. This can
    be done by simple equational reasoning:»

  commentCode [haskellFP|
  |   univToSucc (succToUniv t)
  | ≡ {- by def -}
  |   univToSucc (λ x → bimap id (const x) <$> t)
  | ≡ {- by def -}
  |   bimap id (const ()) <$> t
  | ≡ {- by () having just one element -}
  |   bimap id id <$> t
  | ≡ {- by (bi)functor laws -}
  |   t
  |]
 
  q«The second property ({|succToUniv . univToSucc ≡ id|}) means that
    there is no ``junk'' in the representation:  one cannot
    represent more terms in {|UnivScope|} than in {|SuccScope|}.
    It is more
    difficult to prove, as it 
    and relies on parametricity and in turn on the lack of junk (non-termination or {|seq|}) 
    in the host language. 
    Hence we need to use the free
    theorem for a value {|f|} of type {|UnivScope tm a|}.
    Transcoding {|UnivScope tm a|} to a relation by using Paterson's
    version {cite[fegarasrevisiting1996]} of the abstraction
    theorem {cite[reynolds83,bernardyproofs2012]}, assuming additionally
    that {|tm|} is a functor. We obtain the following lemma:»

  commentCode [haskellFP|
  | ∀ v₁:*. ‼ ∀ v₂:*. ∀ v:v₁ → v₂.
  | ∀ x₁:v₁. ∀ x₂:*. v x₁ ≡ x₂.
  | ∀ g:(a ▹ v₁) → (a ▹ v₂).
  | (∀ y:v₁. New (v y) ≡ g (New y)) →
  | (∀ n:a. ‼ Old n     ≡ g (Old n)) →
  | f x₂ ≡ g <$> f x₁
  |]

  q«We can then specialize {|v₁|} and {|x₁|} to {|()|}, {|v|}
    to {|const x₂|}, and {|g|} to {|bimap id v|}. By definition,
    {|g|} satisfies the conditions of the lemma and we get:»
  commentCode [haskellFP|
  |f x ≡ bimap id (const x) <$> f ()
  |]
  q«We can then reason
    equationally:»

  commentCode [haskellFP|
  |   f
  | ≡ {- by the above -}
  |   λ x → bimap id (const x) <$> f ()
  | ≡ {- by def -}
  |   succToUniv (f ())
  | ≡ {- by def -}
  |   succToUniv (univToSucc f)
  |]

  subsection «{|ExistScope tm a ≅ SuccScope tm a|} »

  p"conversions"
   «The conversion functions witnessing the isomorphism are the
    following.»

  -- if you remove this newpage put back [haskellFP|
  newpage
  [haskellP|
  |succToExist :: SuccScope tm a → ExistScope tm a
  |succToExist = E ()
  |]
  [haskellP|
  |existToSucc :: Functor tm ⇒ 
  |               ExistScope tm a → SuccScope tm a
  |existToSucc (E _ t) = bimap id (const ()) <$> t
  |]

  q«One can recognise the functions {|pack|} and {|unpack|} as CPS
    versions of {|existToSucc|} and {|succToExist|}.»

  q«The proof of {|existToSucc . succToExist ≡ id|} (no junk) is nearly identical
    to the first proof about {|UnivScope|} and hence omitted. To
    prove {|succToExist . existToSucc ≡ id|}, we first remark that by
    definition:»

  commentCode [haskellFP|
  |succToExist (existToSucc (E y t)) ≡
  |  E () (fmap (bimap id (const ())) t)
  |]

  q«It remains to show that {|E y t|} is equivalent to the right-hand
    side of the above equation. To do so, we consider any observation
    function {|o|} of type {|∀ v. v → tm (a ▹ v) → K|} for some constant
    type {|K|}, and show that it returns the same result if applied
    to {|y|} and {|t|} or {|()|} and {|fmap (bimap id (const ()))
    t|}. This fact is a consequence of the free theorem associated
    with {|o|}:»

  commentCode [haskellFP|
  | ∀ v₁:*. ‼ ∀ v₂:*. ∀ v:v₁ → v₂.
  | ∀ x₁:v₁. ∀ x₂:*. v x₁ ≡ x₂.
  | ∀ t₁:tm (a ▹ v₁). ∀ t₂:tm (a ▹ v₂).
  | (∀ g:(a ▹ v₁) → (a ▹ v₂).
  |  (∀ y:v₁. New (v y) ≡ g (New y)) →
  |  (∀ n:a.  Old n     ≡ g (Old n)) →
  |  t₂ ≡ fmap g t₁) →
  | o x₂ t₂ ≡ o x₁ t₁
  |] 

  q«Indeed, after specializing {|x₂|} to {|()|} and {|v|}
    to {|const ()|}, the last condition amounts
    to {|t₂ ≡ fmap (bimap id (const ())) t₁|}, and we get the desired
    result.»

  -- subsection «{|FunScope|}»
  --  «NP: this one comes from NbE»
  onlyInCode [haskellFP|
  |type FunScope tm a = ∀ b. (a → b) → tm b → tm b
  |
  |fmapFunScope :: (a → b) → FunScope tm a → FunScope tm b
  |fmapFunScope f g h x = g (h . f) x
  |
  |returnFunScope :: Monad tm ⇒ a → FunScope tm a
  |returnFunScope x f t = return (f x)
  |
  |bindSuccScope :: Monad tm ⇒ (a → SuccScope tm b) →
  |                   SuccScope tm a → SuccScope tm b
  |bindSuccScope f t = t >>= λ x → case x of
  |  Old y  → f y
  |  New () → return (New ())
  |
  |-- NP: I started this one by converting to
  |-- SuccScope, but so far I'm stuck here
  |bindFunScope :: Monad tm ⇒ (a → FunScope tm b) →
  |                  FunScope tm a → FunScope tm b
  |bindFunScope f t g u =
  |  funToUniv t u >>= λ x → case x of
  |    New y → y
  |    Old y → f y g u
  |
  |existToFun :: Monad tm ⇒ ExistScope tm a
  |                       → FunScope tm a
  |existToFun (E x t) f u = t >>= extend (x, u) (return . f)
  |
  |funToUniv :: Monad tm ⇒ FunScope tm a
  |                      → UnivScope tm a
  |funToUniv f = f Old . return . New
  |
  |-- funToSucc is a special case of funToUniv
  |funToSucc :: Monad tm ⇒ FunScope tm a
  |                      → SuccScope tm a
  |funToSucc f = funToUniv f ()
  |
  |-- succToFun is a special case of existToFun
  |succToFun :: Monad tm ⇒ SuccScope tm a
  |                      → FunScope tm a
  |succToFun = existToFun . E ()
  |]

  subsection $ «A Matter of Style» `labeled` styleSec
  
  q«We have seen that {|ExistScope|} is well-suited for term analysis, while 
  {|UnivScope|} is well-suited for term construction. What about term {emph«transformations»},
  which combine both aspects? In this case, one is free to choose either interface. This 
  can be illustrated by showing both alternatives for the {|Lam|} case of the {|fmap|} function.
  (The {|App|} and {|Var|} cases are identical.) Because the second version is more concise, we prefer it
    in the upcoming examples, but the other choice is equally valid.»
  commentCode [haskellFP|
  |fmap' f (Lam b)
  |   = unpack b $ λ x t → lamP x (fmap (bimap f id) t)
  |fmap' f (Lam b) 
  |   = lam (λ x → fmap (bimap f id) (b `atVar` x))
  |]
  q«When using {|succToUniv|}, the type of the second argument of {|succToUniv|}
    should always be a type variable in order to have maximally polymorphic contexts.
    To remind us of this requirement when writing code, we give the alias {|atVar|} for {|succToUniv|}.
    (Similarly, to guarantee safety, the first argument of {|pack|} (encapsulated here in {|lamP|}) must be maximally polymorphic.)»

  onlyInCode [haskellFP| 
  |atVar = succToUniv
  |]

  subsection $ «Scope Representations and Term Representations»
  
  q«By using an interface such as ours, term representations can be made agnostic to the
    particular scope representation one might choose. In other words, if some interface appears
    well-suited to a given application domain, one might choose it as the scope representation
    in the implementation. Typically, this choice is be guided by performance considerations.
    Within this paper we favor code concision instead, and therefore in sec.
    {ref hereditarySec} we use {|ExistScope|}, and in sections
    {ref closureSec} and {ref cpsSec} we use {|UnivScope|}.
    »

{-
  subsection «Catamorphisms in style»
  q «One can take the example of a size function, counting the number of
    data constructors in a term:»

  [haskellFP|
  |type Size = Int
  |]

  [haskellFP|
  |size :: (a → Size) → Tm a → Size
  |size ρ (Var x)   = ρ x
  |size ρ (App t u) = 1 + size ρ t + size ρ u
  |size ρ (Lam b)   = 1 + size ρ' b
  | where ρ' (New ()) = 1
  |       ρ' (Old  x) = ρ x
  |]

  p"Nominal aspect"
   «However one might prefer to use our interface in particular in larger examples.
    Each binder is simply {|unpack|}ed.
    Using this technique, the size computation looks as follows:»

  [haskellFP|
  |sizeEx :: (a → Size) → Tm a → Size
  |sizeEx ρ (Var x)   = ρ x
  |sizeEx ρ (App t u) = 1 + sizeEx ρ t + sizeEx ρ u
  |sizeEx ρ (Lam b)   = unpack b $ λ x t →
  |                      1 + sizeEx (extend (x,1) ρ) t
  |
  |extend :: (v, r) → (a → r) → (a ▹ v → r)
  |extend (_, x) _ (New _) = x
  |extend _      f (Old x) = f x
  |]

  p"cata"
   «This pattern can be generalized to any algebra over terms, yielding
    the following catamorphism over terms. Note that the algebra
    corresponds to the higher-order representation of λ-terms.»

  [haskellFP|
  |data TmAlg a r = TmAlg { pVar :: a → r
  |                       , pLam :: (r → r) → r
  |                       , pApp :: r → r → r }
  |
  |cata :: TmAlg a r → Tm a → r
  |cata φ s = case s of
  |   Var x   → pVar φ x
  |   Lam b   → pLam φ (λ x → cata (extendAlg x φ) b)
  |   App t u → pApp φ (cata φ t) (cata φ u)
  |
  |extendAlg :: r → TmAlg a r → TmAlg (Succ a) r
  |extendAlg x φ = φ { pVar = pVarSucc }
  |  where
  |    pVarSucc (New _) = x
  |    pVarSucc (Old y) = pVar φ y
  |]

  p"cataSize"
   «Finally, it is also possible to use {|cata|} to compute the size:»

  [haskellFP|
  |sizeAlg :: (a → Size) → TmAlg a Size
  |sizeAlg ρ = TmAlg { pVar = ρ
  |                  , pLam = λ f → 1 + f 1
  |                  , pApp = λ x y → 1 + x + y }
  |
  |cataSize :: (a → Size) → Tm a → Size
  |cataSize = cata . sizeAlg
  |]
-}


{-

  q«
   Our representation features three aspects which are usually kept separate. It
   has a nominal aspect, an higher-order aspect, and a de Bruijn indices aspect.
   Consequently, one can take advantage of the benefits of each of there aspects when
   manipulating terms.

  ...»

  ...

  p"higher-order"«Second, we show the higher-order aspect. It is common in higher-order representations
   to supply a concrete value to substitute for a variable at each binding site.
   Consequently we will assume that all free variables
   are substituted for their size, and here the function will have type {|Tm Int → Int|}.

   In our {|size|} function, we will consider that each variable occurrence as the constant
   size 1 for the purpose of this example.

   This is be realized by applying the constant 1 at every function argument of a {|Lam|} constructor. One then needs
   to adjust the type to forget the difference between the new variable and the others, by applying an {|untag|} function
   for every variable. The variable and application cases then offer no surprises.
   »

  [haskellFP|
  |size1 :: Tm Size → Size
  |size1 (Var x) = x
  |size1 (Lam g) = 1 + size1 (fmap untag (g 1))
  |size1 (App t u) = 1 + size1 t + size1 u
  |]

  -- Scope Tm a → v → Tm (a ▹ v)
  -- Scope Tm a → a → Tm a

  {- NP: not sure about the usefulness of this

  p"de Bruijn"«Third, we demonstrate the de Bruijn index aspect. This time we assume an environment mapping
      de Bruijn indices {|Nat|} to the  their value of the free variables they represent (a {|Size|}
      in our case).
      In the input term, free variables
      are represented merely by their index.
      When going under a binder represented by a function {|g|}, we apply {|g|} to a dummy argument {|()|},
      then we convert the structure of free variables {|Nat :> ()|} into {|Nat|}, using the {|toNat|} function.
      Additionally the environment is extended with the expected value for the new variable.»

  [haskellFP|
  |size3 :: (Nat → Size) → Tm Nat → Size
  |size3 f (Var x) = f x
  |size3 f (Lam g) = 1 + size3 f' (fmap toNat (g ()))
  |  where f' Zero = 1
  |        f' (Succ n) = f n
  |size3 f (App t u) = 1 + size3 f t + size f u
  |
  |toNat (New ()) = Zero
  |toNat (Old x) = Succ x
  |]

  p"mixed style"«
  In our experience it is often convenient to combine the first and third approaches, as we
  illustrate below.
  This time the environment maps an arbitrary context {|a|} to a value.
  For each new variable,
  we pass the size that we want to assign to it to the binding function, and
  we extend the environment to use that value on the new variable, or
  lookup in the old environment otherwise.
  »
  -}
-}


  section $ «Bigger Examples» `labeled` examples
{-

  subsection $ «Test of α-equivalence»
  p""«
   Using our technique, two α-equivalent terms will have the same underlying representation. Despite this property,
   a Haskell compiler will refuse to generate an equality-test via a {|deriving Eq|} clause.
   This is caused by the presence of a function type inside the {|Tm|} type. Indeed, in general, extensional equality
   of functions is undecidable. Fortunately, equality for the parametric function type that we use {emph«is»} decidable.
   Indeed, thanks to parametricity, the functions cannot inspect their argument at all, and therefore it is
   sufficient to test for equality at the unit type, as shown below:
  »
  commentCode [haskellFP|
  |instance Eq a ⇒ Eq (Tm a) where
  |  Var x == Var x' = x == x'
  |  Lam g == Lam g' = g == g'
  |  App t u == App t' u' = t == t' && u == u'
  |]
  -- NP: I would like to see my more general cmpTm

  q«However the application of {|()|} is somewhat worrisome, because now different
    indices might get the same {|()|} type. Even though the possibility of a mistake is very low
    in code as simple as equality, one might want to do more complex analyses where the
    possibility of a mistake is real. In order to preempt errors, one should like to use the {|unpack|}
    combinator as below:»

  commentCode [haskellFP|
  |  Lam g == Lam g' = unpack g  $ λx  t  →
  |                    unpack g' $ λx' t' →
  |                    t == t'
  |]
  q«This is however incorrect. Indeed, the fresh variables {|x|} and {|x'|} would receive incompatible types, and
    in turn {|t|} and {|t'|} would not have the same type and cannot be compared. Hence we must use another variant
    of the {|unpack|} combinator, which maintains the correspondence between contexts in two different terms.»

  [haskellFP|
  |unpack2 :: (∀ v. v → f (a ▹ v)) →
  |           (∀ v. v → g (a ▹ v)) →
  |
  |           (∀ v. v → f (a ▹ v) →
  |                       g (a ▹ v) → b) →
  |           b
  |unpack2 f f' k = k fresh (f fresh) (f' fresh)
  |  where fresh = ()
  |]

  q«One can see {|unpack2|} as allocating a single fresh name {|x|} which is shared between {|t|} and {|t'|}.»

  commentCode [haskellFP|
  |  Lam g == Lam g' = unpack2 g g' $ λ x t t' →
  |                    t == t'
  |]

  [haskellFP|
  |type Cmp a b = a → b → Bool
  |
  |cmpTm :: Cmp a b → Cmp (Tm a) (Tm b)
  |cmpTm cmp (Var x1)    (Var x2)    =
  |  cmp x1 x2
  |cmpTm cmp (App t1 u1) (App t2 u2) =
  |  cmpTm cmp t1 t2 && cmpTm cmp u1 u2
  |cmpTm cmp (Lam f1) (Lam f2) =
  |  unpack f1 $ λ x1 t1 →
  |  unpack f2 $ λ x2 t2 →
  |  cmpTm (extendCmp x1 x2 cmp) t1 t2
  |cmpTm _ _ _ = False
  |
  |-- The two first arguments are ignored and thus only there
  |-- to help the user not make a mistake about a' and b'.
  |extendCmp :: a' → b' → Cmp a b → Cmp (a ▹ a') (b ▹ b')
  |extendCmp _ _ f (Old x) (Old y) = f x y
  |extendCmp _ _ _ (New _) (New _) = True
  |extendCmp _ _ _ _       _       = False
  |]
-}

  subsection $ «Normalization using hereditary substitution» `labeled` hereditarySec
  q«A standard test of binder representations is how well they support normalization. 
    In this section we show how to implement normalization using our constructions.»
  -- Normalization takes terms to their normal forms. 
  q«The following type
    captures normal forms of the untyped λ-calculus: a normal form is
    either an abstraction over a normal form or a neutral term (a variable applied to some normal forms). In
    this definition we use an existential-based version of scopes, which
    we splice in the {|LamNo|} constructor.»

  [haskellFP|
  |data No a where
  |  LamNo :: v → No (a ▹ v) → No a
  |  Neutr :: a → [No a] → No a
  |]

  q«The key to this normalization procedure is that normal forms
    are stable under hereditary substitution {cite hereditarycites}.
    The function performing a hereditary substitution substitutes
    variables for their value, while reducing redexes on the fly.»

  [haskellFP|
  |instance Monad No where
  |  return x = Neutr x []
  |  LamNo x t  >>= θ = LamNo x (t >>= liftSubst x θ)
  |  Neutr f ts >>= θ = foldl app (θ f)((>>= θ)<$>ts)
  |]

  q«The most notable feature of this substitution is the use of {|app|}
    to normalize redexes:»

  [haskellFP|
  |app :: No a → No a → No a
  |app (LamNo x t)  u = substituteOut x u t
  |app (Neutr f ts) u = Neutr f (ts++[u])
  |]

  q«The normalize is then a simple recursion on the term
    structure:»

  [haskellFP|
  |norm :: Tm a → No a
  |norm (Var x)   = return x
  |norm (App t u) = app (norm t) (norm u)
  |norm (Lam b)   = unpack b $ λ x t →
  |                   LamNo x (norm t)
  |]

  when (long || includeUglyCode) $ docNbE nbeSec nbecites

  subsection $ «Closure Conversion» `labeled` closureSec
  q«A common phase in the compilation of functional languages is closure conversion. 
    The goal of closure conversion is make explicit the creation and opening of closures, 
    essentially implementing lexical scope. 
    What follows is a definition of closure conversion, as can be found in a textbook 
    (in fact this version is slightly adapted from {citet[guillemettetypepreserving2007]}).
    In it, we use a hat to distinguish
    object-level abstractions ({tm|\hat\lambda|}) from host-level ones.
    Similarly, the {tm|@|} sign is used for object-level applications. »
  q«
    The characteristic that interests us in this definition is that it is written in nominal style.
    For instance, it pretends that by matching on a {tm|\hat \lambda|}-abstraction, one obtains a name
    {tm|x|} and an expression {tm|e|}, and it is silent about the issues of freshness and
    transport of names between contexts. In the rest of the section, we construct an
    implementation which essentially retains
    these characteristics.
  »
  dmath
   [texm|
   |\begin{array}{r@{\,}l}
   |  \llbracket x \rrbracket &= x \\
   |  \llbracket \hat\lambda x. e \rrbracket &= \mathsf{closure}~(\hat\lambda x~x_\mathnormal{env}. e_\mathnormal{body})\, e_\mathnormal{env} \\
   |                                         &\quad \quad \mathsf{where}~\begin{array}[t]{l@{\,}l}
   |                                                                  y_1,\ldots,y_n & = FV(e)-\{x\} \\
   |                                                                  e_\mathnormal{body} & = \llbracket e \rrbracket[x_{env}.i/y_i] \\
   |                                                                  e_\mathnormal{env} & = \langle y_1,\ldots,y_n \rangle
   |                                                               \end{array}\\
   |  \llbracket e_1@e_2 \rrbracket &= \mathsf{let}~(x_f,x_\mathnormal{env}) = \mathsf{open}~\llbracket e_1 \rrbracket \, \mathsf{in}~ x_f \langle \llbracket e_2 \rrbracket , x_\mathnormal{env} \rangle
   |\end{array}
   |]

  q«The first step in implementing the above function is to define the
    target language. It features variables and applications as usual.
    Most importantly, it has a constructor for {|Closure|}s, composed
    of a body and an environment. The body of closures have exactly two
    free variables: {|vx|} for the parameter of the closure and {|venv|}
    for its environment.
    These variables are represented
    by two {|UnivScope|}s, which we splice in the type of the constructor.
    An environment is realized by a {|Tuple|}.
    Inside the closure, elements of the environment are accessed via
    their {|Index|} in the tuple. Finally, the {|LetOpen|} construction
    allows to access the components of a closure (its first argument)
    in an arbitrary expression (its second argument). This arbitrary
    expression has two extra free variables: {|vf|} for the code of the
    closure and {|venv|} for its environment.
     »

  -- NP: we should either change to SuccScope or mention that we illustrate
  -- here the UnivScope representation.
  -- JP: done at end of sec. 5.4
   

  [haskellFP|
  |data LC a where
  |  VarLC :: a → LC a
  |  AppLC :: LC a → LC a → LC a
  |  Closure :: (∀ vx venv. vx → venv →
  |           LC (Zero ▹ venv ▹ vx)) →
  |           LC a → LC a
  |  Tuple :: [LC a] → LC a
  |  Index :: LC a → Int → LC a
  |  LetOpen :: LC a → (∀ vf venv. vf → venv →
  |                     LC (a ▹ vf ▹ venv)) → LC a
  |]

  q«This representation is an instance of {|Functor|} and {|Monad|}, and
    the corresponding code offers no surprise.

    We give an infix alias for {|AppLC|}, named {|$$|}.»

  onlyInCode [haskellFP|
  |($$) = AppLC
  |infixl $$
  |]

  {-
  [haskellFP|
  |closure :: (∀ vx venv. vx → venv →
  |              LC (Zero ▹ venv ▹ vx)) →
  |           LC a →
  |           LC a
  |closure f t = Closure (f () ()) t
  |
  |letOpen :: LC a →
  |           (∀ vf venv. vf → venv →
  |               LC (a ▹ vf ▹ venv)) → LC a
  |letOpen t f = LetOpen t (f () ())
  |]
  -}

  q«Closure conversion can then be implemented as a function
    from {|Tm a|} to {|LC a|}. The case of variables is trivial. For
    an abstraction, one must construct a closure, whose environment
    contains each of the free variables in the body. The application
    must open the closure, explicitly applying the argument and the
    environment.»

  q«The implementation closely follows the mathematical definition given
    above. The work to manage variables explicitly is limited to the
    lifting of the substitution {tm|[x_{env}.i/y_i]|}, and an application of
    {|wk|}. Additionally, the substitution performed {|wk|} is 
    inferred automatically by GHC.»

  [haskellFP|
  |cc :: Eq a ⇒ Tm a → LC a
  |cc (Var x) = VarLC x
  |cc t0@(Lam b) =
  |  let yn = nub $ freeVars t0
  |  in Closure (λ x env → cc (b `atVar` x) >>=
  |                   liftSubst x (idxFrom yn env))
  |             (Tuple $ map VarLC yn)
  |cc (App e1 e2) =
  |  LetOpen (cc e1)
  |          (λ f x → var f $$ wk (cc e2) $$ var x)
  |]

{-
  Not really relevant since we're not tightly related to Guillemettetypepreserving2007.

  q«The definition of closure conversion we use has a single difference
    compared to {cite[guillemettetypepreserving2007]}: in closure
    creation, instead of binding one by one the free variables {|yn|} in
    the body to elements of the environment, we bind them all at once,
    using a substitution which maps variables to their position in the
    list {|yn|}.»
-}

  q«A notable difference between the above implementation and that of
    {citeauthor[guillemettetypepreserving2007]} is the following.
    They first modify the
    function to take an additional substitution argument, citing the
    difficulty to support a direct implementation with de Bruijn
    indices. We need not do any such modification: our interface is
    natural enough to support a direct implementation of the algorithm.»

  subsection $ «CPS Transform» `labeled` cpsSec

  p"intro"
   «The next example is a transformation to continuation-passing
    style (CPS) based partially on work by {citet[chlipalaparametric2008]} and
    {citet[guillemettetypepreserving2008]}.

    The main objective of the transformation is to make the
    order of evaluation explicit, by {tm|\mathsf{let}|}-binding every intermediate {|Value|} in
    a specific order. To this end, we target a special representation,
    where every intermediate result is named. We allow for {|Value|}s to be
    pairs, so we can easily replace each argument with a pair of an
    argument and a continuation.»

{-
  [haskellFP|
  |data TmC a where
  |  HaltC :: a → TmC a
  |  AppC  :: a → a → TmC a
  |  LetC  :: Value a → TmC (Succ a) → TmC a
  |
  |data Value a where
  |  LamC  :: TmC (Succ a) → Value a
  |  PairC :: a → a → Value a
  |  FstC  :: a → Value a
  |  SndC  :: a → Value a
  |]
-}

  [haskellFP|
  |data TmC a where
  |  HaltC :: Value a → TmC a
  |  AppC  :: Value a → Value a → TmC a
  |  LetC  :: Value a → TmC (Succ a) → TmC a
  |
  |data Value a where
  |  LamC  :: TmC (Succ a) → Value a
  |  PairC :: Value a → Value a → Value a
  |  VarC  :: a → Value a
  |  FstC  :: a → Value a
  |  SndC  :: a → Value a
  |]

  p"smart constructors"
   «We do not use {|Value|}s directly, but instead their composition with injection.»

  {-
  [haskellFP|
  |type UnivScope f a = ∀ v. v → f (a ▹ v)
  |
  |haltC :: (v ∈ a) ⇒ v → TmC a
  |appC  :: (v ∈ a, v' ∈ a) ⇒ v → v' → TmC a
  |letC  :: Value a → UnivScope TmC a → TmC a
  |
  |lamC  :: UnivScope TmC a → Value a
  |pairC :: (v ∈ a, v' ∈ a) ⇒ v → v' → Value a
  |fstC  :: (v ∈ a) ⇒ v → Value a
  |sndC  :: (v ∈ a) ⇒ v → Value a
  |]
  -}

  [haskellFP|
  |varC :: (v ∈ a) ⇒ v → Value a
  |letC :: Value a → UnivScope TmC a → TmC a
  |lamC :: UnivScope TmC a → Value a
  |fstC :: (v ∈ a) ⇒ v → Value a
  |sndC :: (v ∈ a) ⇒ v → Value a
  |]

  -- smart constructor for
  --    λ(x1,x2)→f x1 x2
  -- internally producing
  --    λp→ let x1 = fst p in
  --        let x2 = snd p in
  --        f x1 x2

  p"Functor TmC"
   «Free variables in {|TmC|} can be renamed, thus it enjoys a functor
    structure, with a straightforward implementation found in appendix.
    However, this new syntax {|TmC|} is not stable under substitution.
    Building a monadic structure would be more involved, and is directly
    tied to the transformation we perform and the operational semantics
    of the language, so we omit it.»

  p"the transformation"
   «We implement a one-pass CPS transform (administrative redexes are
    not created). This is done by passing a host-language continuation
    to the transformation. At the top-level the halting continuation
    is used. A definition of the transformation using mathematical
    notation could be written as follows.»

  dmath
   [texm|
   |\begin{array}{r@{\,}l}
   | \llbracket x \rrbracket\,\kappa &= \kappa\,x \\
   | \llbracket e_1 \,@\, e_2 \rrbracket\,\kappa &= \llbracket e_1 \rrbracket (\lambda f. \,
   |                                       \llbracket e_2 \rrbracket (\lambda x. \,
   |                                       f \, @ \, \langle x, \kappa \rangle ) ) \\
   | \llbracket \hat\lambda x. e \rrbracket \kappa &= \mathsf{let}\, f = \hat\lambda p. \begin{array}[t]{l}
   |                                       \mathsf{let}\, x_1 = \mathsf{fst}\, p \,\mathsf{in}\\
   |                                       \mathsf{let}\, x_2  = \mathsf{snd}\, p \,\mathsf{in} \\
   |                                       \llbracket e[x_1/x] \rrbracket (\lambda r.\, x_2 \, @ \, r) \end{array}  \\
   |                                      &\quad \mathsf{in} \, \kappa\,f
   |\end{array}
   |]

  p"latex vs. haskell"
   «The implementation follows the above definition, except for the
    following minor differences. For the {|Lam|} case, the only
    deviation is an occurrence of {|wk|}. In the {|App|} case, we
    have an additional reification of the host-level continuation as a
    proper {|Value|} using the {|lamC|} function.

    In the variable case, we must pass the variable {|v|} to the
    continuation. Doing so yields a value of type {|TmC (a ▹ a)|}.
    To obtain a result of the right type it suffices to remove the
    extra tagging introduced by {|a ▹ a|} everywhere in the term,
    using {|(untag <$>)|}. Besides, we use a number of instances of {|wk|}, 
    and for each of them
    GHC is able to infer the substitution to perform.»

  {-
  [haskellFP|
  |cps :: Tm a → (∀ v. v → TmC (a ▹ v)) → TmC a
  |cps (Var x)     k = fmap untag (k x)
  |cps (App e1 e2) k =
  |  cps e1 $ λ f →
  |  cps (wk e2) $ λ x →
  |  LetC (LamC (λ x → wk (k x))) $ \k' →
  |  LetC (pairC x k') $ \p →
  |  appC f p
  |cps (Lam e')    k =
  |  LetC (LamC $ \p → LetC (fstC p) $ λ x →
  |                   LetC (π2 p) $ \k' →
  |                   cps (wk (e' x)) $ \r →
  |                   appC k' r)
  |      k
  |]
  -}

  -- |cps :: Tm a → Univ TmC a → TmC a
  [haskellFP|
  |cps :: Tm a → (∀ v. v → TmC (a ▹ v)) → TmC a
  |cps (Var x)     k = untag <$> k x
  |cps (App e1 e2) k =
  |  cps e1 $ λ x1 →
  |  cps (wk e2) $ λ x2 →
  |  varC x1 `AppC` (varC x2 `PairC`
  |                  lamC (λ x → wk $ k x))
  |cps (Lam e)    k =
  |  letC
  |    (lamC $ λp →
  |       letC (fstC p) $ λ x1 →
  |       letC (sndC p) $ λ x2 →
  |       cps (wk $ e `atVar` x1) $ λr →
  |       varC x2 `AppC` varC r) k
  |]
{-
  -- This version departs from the mathematical notation and requires an explicit weakening
  [haskellFP|
  |cps :: Tm a → (∀ v. v → TmC (a ▹ v)) → TmC a
  |cps (Var x)     k = untag <$> k x
  |cps (App e1 e2) k =
  |  cps e1 $ λ x1 →
  |  cps (wk e2) $ λ x2 →
  |  AppC (varC x1)
  |       (PairC (varC x2)
  |              (lamC (λ x → wk $ k x)))
  |cps (Lam e)     k =
  |  letC (lamPairC $ λ x1 x2 →
  |        cps (fmap Old $ e `atVar` x1) $ λr →
  |        AppC (varC x2) (varC r)) k
  |
  |cps0 :: Tm a → TmC a
  |cps0 t = cps t $ HaltC . varC
  |]

  -- I suggest inlining this so meaningful names can be used.
  -- |type UnivScope2 f a = forall v1 v2. v1 → v2 → f (a ▹ v1 ▹ v2)
  [haskellFP|
  |lamPairC :: (forall v1 v2. v1 → 
  |             v2 → TmC (a ▹ v1 ▹ v2)) → Value a
  |lamPairC f = lamC $ λp →
  |              letC (fstC p) $ λ x1 →
  |              letC (sndC p) $ λ x2 →
  |              wk $ f x1 x2
  |]
-}

  q«It is folklore that a CPS transformation is easier
    to implement with higher-order abstract syntax
    {cite[guillemettetypepreserving2008,washburnboxes2003]}. Our
    interface for name abstractions features a form of higher-order
    representation. (Namely, a quantification, over a universally
    quantified type.) However limited, this higher-order aspect is
    enough to allow an easy implementation of the CPS transform.»

  section $ «Related Work» `labeled` comparison

  q«Representing names and binders in a safe and convenient manner is
   a long-standing issue, with an extensive body of work devoted to it.
   A survey is far beyond the scope of this paper.
   Hence, we limit our comparison the work that we judge most relevant, 
   or whose contrasts with our proposal is the most revealing.
  »
  q«However, we do not limit our comparison to interfaces for names and
    binders, but also look at terms representations. Indeed, we have 
    noted in sec. {ref styleSec} that every term representation embodies
    an interface for binders.»

  --  «Tell how interfaces of locally-nameless (including Binders
  --  Unbound), α-caml, Fresh(OCaml)ML are all unsafe and require some
  --  side effects.»

  -- JP: I did not do this because all I know has been already said in
  -- the intro.

  subsection $ «{|Fin|}»

  p"Fin approach description"
   «Another approach already used and described by {citet fincites} is
    to index terms, names, etc. by a number, a bound. This bound is the
    maximum number of distinct free variables allowed in the value. This
    rule is enforced in two parts: variables have to be strictly lower
    than their bound, and the bound is incremented by one when crossing
    a name abstraction (a λ-abstraction for instance).»

  p"Fin type description"
   «The type {|Fin n|} is used for variables and represents natural
    numbers strictly lower than {|n|}. The name {|Fin n|} comes from the
    fact that it defines finite sets of size {|n|}.»

  p"Fin/Maybe connection"
   «We can draw a link with Nested Abstract Syntax. Indeed,
    as with the type {|Succ|} ({|(▹ ())|} or {|Maybe|}), the
    type {|Fin (suc n)|} has exactly one more element than the
    type {|Fin n|}. However, these approaches are not equivalent for
    at least two reasons. Nested Abstract Syntax can accept any
    type to represent variables. This makes the structure more like a
    container and this allows to exhibit the substitutive 
    structure of terms as monads. The {|Fin|} approach has advantages as well: the
    representation is concrete and closer to the original
    approach of de Brujin. In particular the representation of
    free and bound variables is more regular, and it may be more amenable
    to the optimization of variables as machine integers.»

  {- There might even be ways to get a similar interface for Fin,
     it might get closer McBride approach, tough -}

  subsection $ «Higher-Order Abstract Syntax (HOAS)»

  q«A way to represent bindings of an object language is via the
    bindings of the host language. One naive translation of this idea
    yields the following term representation:»

  [haskellFP|
  |data TmH = LamH (TmH → TmH) | AppH TmH TmH
  |]

  q«An issue with this kind of representation is the presence of
    so-called “exotic terms”: a function of type {|TmH → TmH|} which
    performs pattern matching on its argument does not necessarily
    represent a term of the object language. A proper realization of the
    HOAS idea should only allow functions which use their argument for
    substitution.»

  q«It has been observed before that one can implement this restriction
    by using polymorphism. This observation also underlies the safety of
    our {|UnivScope|} representation.»

  q«Another disadvantage of HOAS is the negative occurrence
    of the recursive type, which makes it tricky to analyze
    terms {cite[washburnboxes2003]}.»


  subsection «Syntax for free»

  q«{citet[atkeyhoas09]} revisited the polymorphic encoding
    of the HOAS representation of the untyped lambda calculus. By
    constructing a model of System F's parametricity in {_Coq} he could
    formally prove that polymorphism rules out the exotic terms.
    Name abstractions, while represented by computational functions,
    cannot react to the shape of their argument and thus
    behave as substitutions. Here is this representation in {_Haskell}:»

  [haskellFP|
  |type TmF = ∀ a. ({-lam:-} (a → a) → a)
  |             → ({-app:-}  a → a  → a) → a
  |]

  q«And our familiar application function:»

  [haskellFP|
  |apTmF :: TmF
  |apTmF lam app = lam $ λ f → lam $ λ x → f `app` x
  |]

  p"catamorphism only & can't go back"
   «Being a polymorphic encoding, this technique is limited to analyze terms
    via folds (catamorphism). Indeed,
    there is no known safe way to convert a term of this polymorphic
    encoding to another safe representation of names. As Atkey
    shows, this conversion relies on the Kripke version of the
    parametricity result of this type. (At the moment, the attempts to
    integrate parametricity in a programming language only support 
    non-Kripke versions {cite parametricityIntegrationCites}.)»

{- NP: what about putting this in the catamorphism section with a forward ref
  - to here?
  [haskellFP|
  |tmToTmF :: Tm Zero → TmF
  |tmToTmF t lam app = cata (TmAlg magic lam app)
  |]
  -}

  subsection «Parametric Higher-Order Abstract Syntax (PHOAS)» 

  q«{citet[chlipalaparametric2008]} describes a way to represent binders
    using polymorphism and functions. Using that technique, called
    Parametric Higher-Order Abstract Syntax (PHOAS), terms of the
    untyped λ-calculus are as represented follows:»

  [haskellFP|
  |data TmP a where
  |  VarP :: a → TmP a
  |  LamP :: (a → TmP a) → TmP a
  |  AppP :: TmP a → TmP a → TmP a
  |
  |type TmP' = ∀ a. TmP a
  |]

  q«Only universally quantified terms ({|TmP'|}) are
    guaranteed to correspond to terms of the λ-calculus.»

  q«The representation of binders used by Chlipala can be seen as a
    special version of {|UnivScope|}, where all variables are assigned
    the same type. This specialization has pros and cons. On the plus
    side, substitution is easier to implement with PHOAS: fresh variables 
    do not need special treatment. The corresponding implementation
    of the monadic {|join|} is as follows:»

  onlyInCode [haskellP|
  |joinP :: TmP (TmP a) → TmP a
  |]
  [haskellFP|
  |joinP (VarP x)   = x
  |joinP (LamP f)   = LamP (λ x → joinP (f (VarP x)))
  |joinP (AppP t u) = AppP (joinP t) (joinP u)
  |]

  q«On the minus side, all the variables (bound and free) have the
    same representation. This means that they cannot be told apart
    within a term of type {|∀ a. TmP a|}. Additionally, once the type
    variable {|a|} is instantiated to a closed type, one cannot recover
    the polymorphic version. Furthermore while {|Tm Zero|} denotes a
    closed term, {|TmP Zero|} denotes a term {emph«without»} variables, hence no
    term at all. Therefore, whenever a user of PHOAS needs to perform
    some manipulation on terms, they must make an upfront choice of a
    particular instance for the parameter of {|TmP|} that supports
    all the required operations on free variables. This limitation is
    not good for modularity, and for code clarity in general. Another issue
    arises from the negative occurrence of the variable type. Indeed this
    makes the type {|TmP|} invariant: it cannot be made a {|Functor|}
    nor a {|Traversable|} and this not a proper {|Monad|} either.»

  q«The use-case of PHOAS presented by Chlipala is the representation
    of well-typed terms. That is, the parameter to {|TmP|} can be made
    a type-function, to capture the type associated with each variable.
    This is not our concern here, but we have no reason to believe that
    our technique cannot support this, beyond the lack of proper for
    type-level computation in {_Haskell} --- Chlipala uses {_Coq} for his
    development.»

  subsection $ «McBride's “Classy Hack”»

  -- the point of types isn’t the crap you’re not allowed to write,
  -- it’s the other crap you don’t want to bother figuring out.

  p "" «{citet[mcbridenot2010]} has devised a set of combinators to construct
        λ-terms in de Brujin representation, with the ability to refer to
        bound variables by name. Terms constructed using McBride's technique are
        textually identical to terms constructed using ours. Another point of
        similarity is the use of instance search to recover the indices from a
        host-language variable name.
        A difference is that McBride integrates the injection in the abstraction
        constructor rather than the variable constructor. The type of the {|var|} combinator then becomes
        simpler, at the expense of {|lam|}:
        »

  commentCode [haskellFP|
  |lam :: ((∀ n. (Leq (S m) n ⇒ Fin n)) → Tm (S m))
  |       → Tm m
  |var :: Fin n → Tm n
  |]
  q«An advantage of McBride's interface is that it does not require the
    “incoherent instances” extension. »

  -- 'Ordered overlapping type family instances' will improve the
  -- situation for us.

  q«However, because McBride represents variables as {|Fin|}, the types
    of his combinators are less precise ours. Notably, the {|Leq|}
    class captures only one aspect of context inclusion (captured
    by the class {|⊆|} in our development), namely that one context
    should be smaller than another. This means, for example, that the
    class constraint {|a ⊆ b|} can be meaningfully resolved in more
    cases than {|Leq m n|}, in turn making functions such as {|wk|}
    more useful in practice. Additionally, our {|unpack|} and {|pack|}
    combinators extend the technique to term analysis and manipulation.»

  subsection $ «{_NomPa} (nominal fragment)» -- TODO: NP (revise -- optional eq. tests.) 

{-
    -- minimal kit to define types
    World  : Set
    Name   : World → Set
    Binder : Set
    _◅_    : Binder → World → World

    -- An infinite set of binders
    zeroᴮ : Binder
    sucᴮ  : Binder → Binder

    -- Converting names and binders back and forth
    nameᴮ   : ∀ {α} b → Name (b ◅ α)
    binderᴺ : ∀ {α} → Name α → Binder

    -- There is no name in the empty world
    ø      : World
    ¬Nameø : ¬ (Name ø)

    -- Names are comparable and exportable
    _==ᴺ_   : ∀ {α} (x y : Name α) → Bool

    -- The fresh-for relation
    _#_  : Binder → World → Set
    _#ø  : ∀ b → b # ø
    suc# : ∀ {α b} → b # α → (sucᴮ b) # (b ◅ α)

    Since we follow a de Bruijn style these are moot: type (:#) a b = (),
      const (), const ()

    -- inclusion between worlds
    _⊆_     : World → World → Set
    coerceᴺ  : ∀ {α β} → (α ⊆ β) → (Name α → Name β)
    ⊆-refl  : Reflexive _⊆_
    ⊆-trans : Transitive _⊆_
    ⊆-ø     : ∀ {α} → ø ⊆ α
    ⊆-◅     : ∀ {α β} b → α ⊆ β → (b ◅ α) ⊆ (b ◅ β)
    ⊆-#     : ∀ {α b} → b # α → α ⊆ (b ◅ α)

    In Haskell respectively (->), id, id, (.), magic, λf -> bimap f id,
      const Old.

  zeroᴮ : Binder
  zeroᴮ = Zero

  sucᴮ : Binder → Binder
  sucᴮ = Succ

* name abstraction
ƛ   : ∀ b → Tm (b ◅ α) → Tm α
-}

  p""
   «{citet[pouillardunified2012]} describe an interface for names and
    binders which provides maximum safety. The library {_NomPa} is
    written in {_Agda}, using dependent types. The interface makes use
    of a notion of {|World|}s (intuitively a set of names), {|Binder|}s
    (name declaration), and {|Name|}s (the occurrence of a name).

    A {|World|}   can   either   be {|Empty|}   (called {|ø|}   in   the
    library {_NomPa}) in or  result of the addition  of a {|Binder|} to
    an existing {|World|}, using the operator {|(◅)|}. The type {|Name|}
    is indexed by {|World|}s: this ties occurrences to the context where
    they make sense.»

  commentCode [haskellFP|
  |World :: *
  |Binder :: *
  |Empty :: World
  |(◅) :: Binder → World → World
  |Name :: World → *
  |]

  p""«
  On top of these abstract notions, one can construct the following representation of terms (we use
  a {_Haskell}-style syntax for dependent types, similar to that of {_Idris}):
  »

  commentCode [haskellFP|
  |data Tm α where
  |  Var :: Name α → Tm α
  |  App :: Tm α → Tm α → Tm α
  |  Lam :: (b :: Binder) → Tm (b ◅ α) → Tm α
  |]

  q«The safety of the technique comes from the abstract character of the
    interface. If one were to give concrete definitions for {|Binder|},
    {|World|} and their related operations, it would become possible for user
    code to cheat the system.

    A drawback of the interface being abstract is that some subterms
    do not evaluate. This point is of prime concern in the context of
    reasoning about programs involving binders.

    In contrast, our interfaces are concrete (code using it
    always evaluates), but it requires the user to choose the
    representation appropriate to the current use ({|SuccScope|},
    {|UnivScope|} or {|ExistScope|}).»

  {- NP

    NomPa names are always comparable for equality (when they inhabit a common
    world). I would now prefer some notion of equality-world (Eqᵂ).

    Eqᵂ : World → Set
    _==ᴺ_ : ∀ {α} {{αᴱ : Eqᵂ α}} → Name α → Name α → Bool

    and then some rules for Eqᵂ (instances):

    øᴱ : Eqᵂ ø
    _◅ᴱ_ : ∀ {α} b → Eqᵂ α → Eqᵂ (b ◅ α)
    _+1ᴱ : ∀ α → Eqᵂ α → Eqᵂ (α +1)

    Derived
    _↑1ᴱ : ∀ α → Eqᵂ α → Eqᵂ (α ↑1)
    α ↑1ᴱ = 0ᴮ ◅ᴱ (α +1ᴱ)

    The goal then would be to gain stronger free-theorems for instance:
      E = ∀ {α} → Eqᵂ α → Tm α → Tm α

      vs.

      F = ∀ {α} → Tm α → Tm α

    In the old model both where undistinguished. Now E is as the old one
    and F is stronger. Functions of type E commutes with injective functions,
    and F commutes with all functions.

    It seems that the construction would be as follows:
    ⟦World⟧ was a relation on names which preserves equalities, now have
    two parts:

    ⟦World⟧ α₁ α₂ = Name α₁ → Name α₂ → Set

    ⟦Eqᴱ⟧ αᵣ = Preserve-≡ αᵣ
    -- expanded
    ⟦Eqᴱ⟧ αᵣ = ∀ x₁ y₁ x₂ y₂ → αᵣ x₁ x₂ → αᵣ y₁ y₂
                             → x₁ ≡ y₁ ↔ x₂ ≡ y₂

    ⟦Name⟧ = id
    -- expanded
    ⟦Name⟧ αᵣ x₁ x₂ = αᵣ x₁ x₂

    ⟦ø⟧ and _⟦◅⟧_ carry only their relation part.
    ⟦øᴱ⟧ and _⟦◅ᴱ⟧_ carry the preservation property.

    _⟦==ᴺ⟧_ is the only one needing this property and now it's the only
    one receiving it!

    The main benefit is when using a parametricity theorem of a truly
    (no Eq) world-polymorphic object, we would now be able to pick any
    relation and thus such a relation can be the graph (i.e. underlying
    relation) of any function!

    In the end this seems like to fit very nicely altogether and the design
    was really close to that. One question could be: What process could
    have let us uncover this sooner? I think that definition of ⟦World⟧ was
    culprit. It was a subset of all the relations and this should seen as
    a signal for further separation of concerns.
  -}

  
  

{-

  Functor f =>
  f () ≅ ∀ v. v → f v ≅ ∃ v. (v, f v)

  to :: f () → ∃ v. (v, f v)
  to t = ((), t)

  {- recall the definition of void from Control.Monad

  -- | @'void' value@ discards or ignores the result of evaluation, such as the return value of an 'IO' action.
  void :: Functor f => f a -> f ()
  void = fmap (const ())
  -}

  from :: Functor f => ∃ v. (v, f v) → f ()
  from (_, t) = void t

  to (from (x, t)) = to (void t)
                   = ((), void t)
                   TODO
                   ... this works because of the way "extensional" equality on existentials (should) work

  ⟨ f ⟩ x y = f x ≡ y
  (⟨ id ⟩ x y) ≡ (id x ≡ y) ≡ (x ≡ y)

  ⟦f⟧ : (a → b → ★) → f a → f b → ★

  ⟦f⟧-refl : ∀ x → ⟦f⟧ _≡_ x x

  ⟦f⟧-fmap : ∀ g x → ⟦f⟧ ⟨ g ⟩ x (fmap g x)

    note that
      ⟦f⟧-fmap id : ∀ x → ⟦f⟧ ⟨ id ⟩ x (fmap id x)
                  : ∀ x → ⟦f⟧ ⟨ id ⟩ x (id x)
                  : ∀ x → ⟦f⟧ ⟨ id ⟩ x x
                  : ∀ x → ⟦f⟧ _≡_    x x
   so
      ⟦f⟧-refl = ⟦f⟧-fmap id -- provided fmap id = id

  R-∃ : (p1 p2 : ∃ a. f a) → ★
  R-∃ (X1 , x1) (X2 , x2) = ⟦f⟧ Full x1 x2

  ∀ (t :: f ()) -> void t = t

  -- at type (), const () = id
  const () ≗ id :: () -> ()

  -- at type (), void = id
  void = fmap (const ()) = fmap id = id :: Functor f => f () -> f ()

  from (to t) = from ((), t)
              = void t
              = t
-}

  --------------------------------------------------
  -- JP
  section $ «Discussion» `labeled` discussion

  subsection «Binding Many Variables» 
  q«
    In {|SuccScope|}, there is exactly one more free variable available in the sub-term.
    However, it might be useful to bind multiple names at once in a binder. This can 
    be done by using a type {|n|} of the appropriate cardinality instead of {|()|}.
    This technique has been used for example by {citet[boundkmett12]}.»
  [haskellFP|
  |type NScope n tm a = tm (a ▹ n)
  |]
  q«Adapting the idea to our framework would mean to quantify over a family of types,
    indexed by a type {|n|} of the appropriate cardinality:»
  commentCode [haskellFP|
  |type NUnivScope  n tm a = ∀v. (n → v) → tm (a ▹ v)
  |type NExistScope n tm a = ∃v.((n → v) , tm (a ▹ v))
  |]

  subsection $ «Delayed Substitutions»

  q«The main performance issue with de Brujn indices comes from the cost of importing
    terms into scopes without capture, which requires to increment
    free-variables in the substituted term (see {|fmap Old|} in the definition of {|liftSubst|}). 
    This transformation incurs not only a direct cost proportional to the size of terms,
    but also an indirect cost in the form of loss of sharing.»

  q«{_Citet[birdpaterson99]} propose a solution to this issue, which can be expressed
     simply as another implementation of binders, where free variables of the inner term stand for 
     whole terms with one less free variables:»

  [haskellFP|
  |type DelayedScope tm a = tm (tm a ▹ ())
  |]

  q«This means that the parallel substitution for a term representation 
    based on {|DelayedScope|} does not require lifting of substitutions.»

  [haskellFP|
  |data TmD a where
  |  VarD :: a → TmD a
  |  LamD :: DelayedScope TmD a  → TmD a
  |  AppD :: TmD a → TmD a → TmD a
  |]

  [haskellP|
  |instance Monad TmD where
  |  return = VarD
  |  VarD a >>= θ = θ a
  |  AppD a b >>= θ = AppD (a >>= θ) (b >>= θ)
  |  LamD t >>= θ = LamD (bimap (>>= θ) id <$> t)
  |]

  onlyInCode [haskellP|
  |instance Functor TmD where
  |  fmap = liftM
  |]

  q«Because idea of delayed substitutions is concerned with free variables, and
    the concepts we present here is concerned with bound variables, one can
    one can easily define scopes which are both delayed and safe. Hence
    the performance gain can is compatible with our safe interface.»

  commentCode [haskellFP|
  |type UnivScope'  tm a = ∀v. (v → tm (tm a ▹ v))
  |type ExistScope' tm a = ∃v. (v ,  tm (tm a ▹ v))
  |]

{-
    Kmett's
    type {|Scope|} not only help improving performances but supports
    multiple binders and enjoys a structure of monad transformers.
    
JP: Why? and how does this fit with our interfaces?

-}


  subsection «Future Work: Improving Safety»
  q«As it stands our interface prevents mistakes in the manipulation of de Bruijn indices, but
    requires a collaboration from the user. 
    Indeed, a malicious user can instantiate {|v|} 
    to a monotype either in the analysis of
    {|∀ v. v → tm (a ▹ v)|} or in the construction of {|∃ v. (v, tm (a ▹ v))|}. This situation can be improved 
    by providing a quantifier which allows to substitute for type variables only other type variables.
    This
    quantifier can be understood as being at the same time existential and universal, 
    and hence is self dual.
    We use the notation {|∇|} (pronounced nabla) for it, due to the similarity with the quantifier
    of the same name introduced by {citet[millerproof2003]}.
    We would then have the following definitions, and safety could not be compromised. »

  commentCode [haskellFP|
   |type UnivScope  tm a = ∇ v.  v → tm (a ▹ v)
   |type ExistScope tm a = ∇ v. (v ,  tm (a ▹ v))
   |]
  q«
   These definitions would preclude using {|SuccScope|} as an implementation, 
   however this should not cause any issue: either of the above could be used directly
   as an implementation.
   Supporting our version of {|∇|} in a type-checker seems a rather modest extension,
   therefore we wish to investigate how some future version of GHC could support it.
   »

  subsection «Future Work: Improve Performance»
  -- NP: univToSucc is cheap as well no?
  q«An apparent issue with the presented conversion functions between
    {|UnivScope|} or {|ExistScope|} on one side and {|SuccScope|} on the
    other side is that all but {|succToExist|} cost a time 
    proportional to the size of the term converted. In the current state of affairs, we 
    might be able to use a system of rewrite rules, such as that implemented in GHC, to 
    eliminate the conversions to and from the safe interfaces. However, within
    a system which supports ∇-quantification, a better option offers itself:
    the machine-representation of the type {|v|} should be
    nil (nothing at all) if {|v|} is a ∇-bound variable; 
    therefore the machine-implementation of the conversions
    can be the identity.»

  subsection «Future Work: No Injections»

  p "getting rid of the injections by using a stronger type system" «
    We use the instance search of GHC in a very specific way: only to discover in injections.
    This suggests that a special-purpose type-system (featuring a form of subtyping)
    could be built to take care of those injections automatically.
    An obvious benefit would be some additional shortening of programs manipulating terms.
    Additionally, this simplification of programs would imply an
    even greater simplification of the proofs about them; indeed, a variation in complexity in
    an object usually yields a greater variation in complexity in proofs about it.
  »

  subsection «Conclusion»
  q«
  We have shown how to make de Bruijn indices safe, by typing them precisely with 
  the context where they make sense. Such precise contexts are obtained is by using (appropriately)
  either of the interfaces {|UnivScope|} or {|ExistScope|}. These two interfaces can 
  be seen as the both sides of the ∇ quantifier of {citet [millerproof2003]}. 
  Essentially, we have deconstructed that flavor of quantification over names, 
  and implemented it in {_Haskell}. The result is a safe method to manipulate names
  and binders, which is supported by today's Glasgow Haskell Compiler.»
  q«
  The method preserves the good properties of de Bruijn indices, while providing
  a convenient interface to program with multiple open binders. We have illustrated 
  these properties by exhibiting the implementation of a number of examples.
  »


  acknowledgments
   «We thank Emil Axelsson, Koen Claessen, Daniel Gustafsson and Patrik Jansson for
    useful feedback.»  -- In alphabetical order 

appendix = execWriter $ do
  section $ «Implementation details» `labeled` implementationExtras
  subsection «Traversable»
  [haskellP|
  |instance Foldable Tm where
  |  foldMap = foldMapDefault
  |]


  subsection «Normalization»
  [haskellP|
  |instance Functor No where 
  |  fmap f (LamNo x t)  = 
  |     LamNo x (fmap (bimap f id) t)
  |  fmap f (Neutr x ts) =
  |     Neutr (f x) (fmap (fmap f) ts)
  |
  |lamNo :: (∀ v. v → No (a ▹ v)) → No a
  |lamNo f = LamNo () (f ())
  |]

  subsection «CPS»

{-
  |  fmap f (FstC x)    = FstC (f x)
  |  fmap f (SndC x)    = SndC (f x)
  |  fmap f (PairC x y) = PairC (f x) (f y)
  |  fmap f (LamC t)    = LamC (fmap (bimap f id) t)

  |  fmap f (HaltC x)  = HaltC (f x)
  |  fmap f (AppC x y) = AppC (f x) (f y)
  |  fmap f (LetC p t) = LetC (fmap f p) (fmap (bimap f id) t)
  -}
  [haskellP|
  |instance Functor Value where
  |  fmap f (VarC x)      = VarC (f x)
  |  fmap f (FstC x)      = FstC (f x)
  |  fmap f (SndC x)      = SndC (f x)
  |  fmap f (PairC v1 v2) = 
  |     PairC (fmap f v1) (fmap f v2)
  |  fmap f (LamC t)      =
  |     LamC (fmap (bimap f id) t)
  |
  |instance Functor TmC where
  |  fmap f (HaltC v)    = HaltC (fmap f v)
  |  fmap f (AppC v1 v2) = 
  |     AppC  (fmap f v1) (fmap f v2)
  |  fmap f (LetC p t)   = 
  |     LetC (fmap f p) (fmap (bimap f id) t)
  |]

  [haskellP|
  |letC p f = LetC p (f ())
  |varC = VarC . inj
  |lamC f = LamC (f ())
  |fstC = FstC . inj
  |sndC = SndC . inj
  |]

{-
  |letC p f  = LetC p (f ())
  |lamC f    = LamC (f ())
  |pairC x y = PairC (inj x) (inj y)
  |fstC      = FstC . inj
  |sndC      = SndC . inj
  |appC x y  = AppC (inj x) (inj y)
  |haltC     = HaltC . inj
  -}

  [haskellP|
  |cps0 :: Tm a → TmC a
  |cps0 t = cps t $ HaltC . varC
  |]

  subsection «Closure Conversion»

  [haskellP|
  |idxFrom :: Eq a ⇒ [a] → v → a → LC (Zero ▹ v)
  |idxFrom yn env z = Index (var env) $
  |                   fromJust (elemIndex z yn)
  |
  |instance Functor LC where
  |  fmap f t = t >>= return . f
  |
  |instance Monad LC where
  |  return = VarLC
  |  VarLC x >>= θ = θ x
  |  Closure c env >>= θ = Closure c (env >>= θ)
  |  LetOpen t g >>= θ = LetOpen (t >>= θ) 
  |    (λ f env → g f env >>= 
  |        liftSubst env (liftSubst f θ))
  |  Tuple ts >>= θ = Tuple (map (>>= θ) ts)
  |  Index t i >>= θ = Index (t >>= θ) i
  |  AppLC t u >>= θ = AppLC (t >>= θ) (u >>= θ)
  |]

  section $ «Bind and substitute an arbitrary name»
  [haskellP|
  |packGen _ t x = fmap (shuffle cx) t
  |  where cx :: v → w
  |        cx _ = x
  |
  |class (v ∈ b) ⇒ Insert v a b where
  |  -- inserting 'v' in 'a' yields 'b'.
  |  shuffle :: (v → w) → b → a ▹ w
  |
  |instance Insert v a (a ▹ v) where
  |  shuffle f (New x) = New (f x)
  |  shuffle f (Old x) = Old x
  |
  |instance Insert v a b ⇒ 
  |         Insert v (a ▹ v') (b ▹ v') where
  |  shuffle f (New x) = Old (New x)
  |  shuffle f (Old x) = case shuffle f x of
  |    New y → New y
  |    Old y → Old (Old y)
  |
  |substituteGen :: 
  |   (Insert v a b, Functor tm, Monad tm) ⇒ 
  |   v → tm a → tm b → tm a
  |substituteGen x t u = 
  |   substituteOut x t (fmap (shuffle id) u)
  |]

  {- commented out until there is a reference to it from the body
  section $ «NomPa details»
  [haskellP|
  |-- ¬Nameø : ¬ (Name ø)
  |noEmptyName :: Zero → a
  |noEmptyName = magic
  |
  |-- nameᴮ : ∀ {α} b → Name (b ◅ α)
  |name :: b → a ▹ b
  |name = New
  |
  |-- ⊆-# : ∀ {α b} → b # α → α ⊆ (b ◅ α)
  |import_ :: a → a ▹ b
  |import_ = Old
  |
  |-- In Agda: exportᴺ? : 
  |-- ∀ {b α} → Name (b ◅ α) → Maybe (Name α)
  |exportM :: a ▹ b → Maybe a
  |exportM (New _) = Nothing
  |exportM (Old x) = Just x
  |
  |-- In Agda: exportᴺ : 
  |-- ∀ {α b} → Name (b ◅ α) → Name (b ◅ ø) ⊎ Name α
  |export :: a ▹ b → Either (Zero ▹ b) a
  |export (New x) = Left (New x)
  |export (Old x) = Right x
  |
  |-- ⊆-◅ : ∀ {α β} b → α ⊆ β → (b ◅ α) ⊆ (b ◅ β)
  |-- fmap of (▹ b)
  |-- ⊆-ø : ∀ {α} → ø ⊆ α
  |-- magic :: Zero → a
  |]
  -}
  stopComment
  stopComment
  stopComment
  stopComment
  stopComment
  return ()
-- }}}

-- {{{ build
-- NP: what about moving this outside, such as run.sh
-- JP: Nope. I'd rather not leave emacs haskell mode.
refresh_jp_bib = do
  let jpbib = "../../gitroot/bibtex/jp.bib"
  e ← doesFileExist jpbib
  when e $ do hPutStrLn stderr "refreshing bib"
              void . system $ "cp " ++ jpbib ++ " ."

main = do
  args ← getArgs
  refresh_jp_bib
  case args of
    ["--tex"]      → printLatexDocument (doc False)
    ["--comments"] → printComments      (doc True)
    [] → do
      writeCommentsTo "PaperCode.hs"  (doc True)
      compile ["sigplanconf"] "main"  (doc False)
    _ → error "unexpected arguments"

categ = Kit.cat «D.3.3» «Language Constructs and Features» «»


doc includeUglyCode = document title authors keywords abstract categ (body includeUglyCode) appendix
-- }}}

-- vim: foldmarker
-- -}


{-

∇ in F2:

Typing:

  Γ,β ⊢ t : ∇α. T[α] 
---------------------    ∇-elim
   Γ ⊢ t @ β : T[β]

note: to make sure that a single variable is not used twice /by the
∇-elim rule/ it's eaten up.  (Technically β should be marked 'eaten'
in the context instead of being summarily removed, since it can be
used as an index in some type family (a subterm of T))


   Γ,α ⊢ t : T[α]
----------------------   ∇-intro
  Γ ⊢ ∇α.t : ∇α. T[α]


Computation:

(∇α.t) @ β  ---> t[β/α]
∇α.(t @ β)  ---> ∇β.t

-- not sure about the rule above, what about this:
∇α.(t @ α)  ---> t

fresh :: ∇v.v
fresh = ∇v.v

var :: ∇v. Tm v
var = ∇v. Var v

Lam :: (∇v. Tm (a ▹ v)) → Tm a

apTm = Lam (α, Lam (β, App (Old (New (var @ α))) (New (var @ β))))

case t of
  Lam (b :: ∇v.Tm(a▹v)) ->
    Lam (∇α. App (b @ α) (b @ α)) -- ill typed because α is used twice
    -- but
    Lam (∇α. let t = b @ α in App t t) -- is fine

Pie in the sky:
---------------

We can then represent binders as:

∇v. v ⊗ (v → Tm (a ▹ v))


- 'destroying'/analysis of the term is done by applying the function to the 1st
  argument of the pair.
- constructing a term feels like it should use excluded middle (of LL) to
  produce the argument of the pair from whatever is passed to the function.
  Intuitively, you can do this because any code using either component of the pair
  must use the other part as well. Unfortunately I cannot see how to implement this
  technically.


Linear logic treatment of ∇:

   α; Γ, A[α] ⊢
------------------ ∇
   Γ, ∇α.A[α] ⊢


∇ eliminates with itself:


   α; Γ, A[α] ⊢              β; Δ, ~A[β] ⊢
------------------ ∇      ------------------ ∇
   Γ, ∇α.A[α] ⊢              Γ, ∇β.~A[β] ⊢
----------------------------------------------- cut
        Γ, Δ ⊢


   α; Γ, A[α] ⊢              α; Δ, ~A[α] ⊢
----------------------------------------------- cut
      α; Γ, Δ ⊢ prf
   --------------------
      Γ, Δ ⊢ να. prf


For the fun we can also see the following, but that's just
a bonus:

∇ eliminates with ∃ (identical to the above)
∇ eliminates with ∀:


  α; Γ, A[α] ⊢              Δ, ~A[B] ⊢
------------------ ∇      ------------------ ∀
   Γ, ∇α.A[α] ⊢              Γ, ∀β.~A[β] ⊢
----------------------------------------------- cut
        Γ, Δ ⊢


   Γ, A[~B] ⊢              Δ, ~A[B] ⊢
----------------------------------------------- cut
        Γ, Δ ⊢


So it's easy to see that ∇ is a subtype of ∃ and ∀.



-}


--  LocalWords:  pollacksatoricciotti belugamu fincites nestedcites
--  LocalWords:  mcbridemckinna birdpaterson altenkirchreus nbecites
--  LocalWords:  bergernormalization licataharper pouillardunified tm
--  LocalWords:  parametricityIntegrationCites kellerparametricity FV
--  LocalWords:  bernardycomputational bernardytypetheory Agda's apTm
--  LocalWords:  hereditarycites polymorphism intodo notetodo haskellFP
--  LocalWords:  notecomm doComment ParItemW startComment stopComment
--  LocalWords:  commentWhen commentCode unpackCode canEta freshFor
--  LocalWords:  isOccurenceOf canEtaWithSig haskellP Nompa morphism TmB
--  LocalWords:  fmap isClosed Foldable Traversable untyped VarB AppB
--  LocalWords:  representable debruijnlambda LamB apB naïve bimap vx
--  LocalWords:  parameterizes onlyInCode cardinality untag Bifunctor
--  LocalWords:  apNested const unicity nabla natively NExistScope
--  LocalWords:  quantifing packGen lamP freeVars recurse occursIn vf
--  LocalWords:  injMany functoriality functorial parameterized atVar
--  LocalWords:  monadic injective Monads Kleisli liftSubst SuccScope
--  LocalWords:  UnivScope substituteOut effectful mcbrideapplicative
--  LocalWords:  bitraverse traversable toList forall ExistScope cata
--  LocalWords:  existentials isomorphisms succToUniv univToSucc pVar
--  LocalWords:  equational Transcoding Paterson fegarasrevisiting
--  LocalWords:  bernardyproofs equationally succToExist existToSucc
--  LocalWords:  FunScope fmapFunScope returnFunScope TmAlg
--  LocalWords:  bindSuccScope bindFunScope funToUniv existToFun pLam
--  LocalWords:  funToSucc succToFun sizeEx pApp extendAlg pVarSucc
--  LocalWords:  cataSize sizeAlg toNat cmpTm Cmp cmp extendCmp LamNo
--  LocalWords:  Neutr redexes foldl includeUglyCode docNbE dmath env
--  LocalWords:  guillemettetypepreserving llbracket rrbracket ldots
--  LocalWords:  mathnormal langle rangle venv LetOpen VarLC AppLC yn
--  LocalWords:  infixl letOpen idxFrom fromJust elemIndex TmC HaltC
--  LocalWords:  chlipalaparametric AppC LetC LamC PairC FstC SndC eq
--  LocalWords:  VarC haltC appC letC lamC pairC fstC sndC varC fst
--  LocalWords:  snd lamPairC inlining washburnboxes caml OCaml suc
--  LocalWords:  Brujn DelayedScope TmD VarD LamD AppD TmH LamH AppH
--  LocalWords:  atkeyhoas TmF apTmF Kripke tmToTmF PHOAS TmP VarP vn
--  LocalWords:  AppP joinP modularity mcbridenot NomPa Nameø refl
--  LocalWords:  Idris equalities boundkmett NScope NUnivScope
--  LocalWords:  millerproof Axelsson Gustafsson
