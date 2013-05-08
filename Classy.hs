{-# LANGUAGE FlexibleInstances, MultiParamTypeClasses, Rank2Types,
             UnicodeSyntax, TypeOperators, GADTs, OverlappingInstances,
             UndecidableInstances, IncoherentInstances, OverloadedStrings, StandaloneDeriving, KindSignatures, RankNTypes, ScopedTypeVariables #-}
module Classy where

import Prelude hiding (sequence,elem)
import Data.String
import Data.List (nub,elemIndex)
import Data.Maybe (fromJust)
import Control.Monad (join)
import Data.Functor
import Control.Applicative
import Data.Traversable
import Data.Foldable
import Data.Monoid

--------------------------------
-- Generic programming prelude

type (∪) a b = (:▹) a b

data (:▹) a b = There a | Here b 
data Zero

elim :: (γ -> a) -> (v -> a) -> γ :▹ v -> a
elim f g (There x) = f x
elim f g (Here x) = g x
  
deriving instance Eq Zero
magic :: Zero -> a
magic _ = error "magic!"
instance Show Zero where show = magic

instance (Show a, Show b) => Show (a :▹ b) where
  show (There x) = show x
  show (Here x) = show x

-------------------------------------------
-- Names as a simple wrapper around strings

newtype Name = Name { unName :: String }

-- Show them without quotes
instance Show Name where
  show = unName

instance IsString Name where
  fromString = Name . fromString

----------------------------------------
-- Term representation and examples

data Term v where
  Var :: v → Term v
  Lam :: Name → (forall w. w → Term (v :▹ w)) → Term v
  App :: Term v → Term v → Term v
   

var :: Monad m => forall a γ. (a :∈ γ) => a → m γ
var = return . lk

lam :: Name → (forall w. w → Term (v ∪ w)) → Term v
lam = Lam

-- A closed term can be given the 'Term Zero' type.
-- More generally any type can be used as the type
-- of the free variables of a closed term including
-- a polymorphic type.
idZero :: Term Zero
idZero = lam "x" (\x → var x)


-- fmap magic, wk...

id' :: Term a
id' = lam "x" (\x → var x)

const' :: Term a
const' = lam "x" (\x → lam "y" (\_y → var x))

testfv :: Term String
testfv = Var "x1" `App` Lam "x2" (\x2->
           Var (There "x3") `App` var x2)

(@@) :: Term a -> Term a -> Term a
Lam _ f @@ u = f u >>= subst0
t       @@ u = App t u

-- oops' = lam "x" (\x → lam "y" (\y → Var (Here x)))

---------------------
-- Display code

instance Show x => Show (Term x) where
  show = disp

-- half broken since names are never freshen
disp :: Show x => Term x → String
disp (Var x)    = show x
disp (App a b)  = "(" ++ disp a ++ ")" ++ disp b
disp (Lam nm f) = "λ" ++ unName nm ++ "." ++ disp (f nm)

data Disp a = Disp { dispVar :: a -> String
                   , curDispId :: Int }

extDisp :: Name -> Disp a -> Disp (a ∪ w)
extDisp nm (Disp v n) = Disp v' (n+1) where
  v' (There a) = v a
  v' (Here _) = show (mkName nm n)

mkName :: Name -> Int -> Name
mkName (Name nm) i = Name $ nm ++ show i

--dispVar :: Disp a -> Term a → ShowS

text :: String -> ShowS
text s1 s2 = s1 ++ s2

disp' :: Disp a -> Term a → ShowS
disp' d (Var x)    = text (dispVar d x)
disp' d (App a b)  = text "(" . disp' d a . text ")" . disp' d b
disp' d (Lam nm f) = text "λ" . text (show nm') . text "." . disp' d' (f ())
  where d'  = extDisp nm d
        nm' = mkName nm (curDispId d)

dispZero :: Term Zero -> String
dispZero t = disp' (Disp magic 0) t ""

printZero :: Term Zero -> IO ()
printZero = putStrLn . dispZero

---------------------
-- Catamorphism

cata :: (b -> a) -> ((a -> a) -> a) -> (a -> a -> a) -> Term b -> a
cata fv _  _  (Var x)   = fv x
cata fv fl fa (App f a) = fa (cata fv fl fa f) (cata fv fl fa a)
cata fv fl fa (Lam _ f) = fl (cata (extend fv) fl fa . f)
  
extend :: (a -> b) -> (a ∪ b) -> b
extend g (Here a) = a
extend g (There b) = g b
        
-----------------------------------------------------------
-- Terms are monads
-- (which means they support substitution as they should)

wk :: (Functor f, γ :< δ) => f γ -> f δ
wk = fmap inj

-- Kleisli arrows arising from the Term monad
type Kl m v w = v → m w

-- Union is a functor in the category of Kleisli arrows
lift :: (Functor f, Monad f) => Kl f v w → Kl f (v :▹ x) (w :▹ x)
lift θ (There x) = wk (θ x)
lift _ (Here x) = var x

instance Monad Term where
  Var x    >>= θ = θ x
  Lam nm t >>= θ = Lam nm (\x → t x >>= lift θ)
  App t u  >>= θ = App (t >>= θ) (u >>= θ)

  return = Var

subst :: Monad m => (v → m w) → m v → m w
subst = (=<<)

-- As with any monad, fmap can be derived from bind and return.
-- This is a bit nasty here though. Indeed the definition of bind
-- uses lift which uses wk which uses fmap.
instance Functor Term where
  fmap f t = t >>= return . f

-- Substitute in an open term
subst' :: (∀v. v → Term v) → Term w → Term w
subst' t u = join (t u)


-- Nbe (HOAS-style)
eval :: Term v -> Term v
eval (Var x) = Var x
eval (Lam n t) = Lam n (eval . t)
eval (App t u) = app (eval t) (eval u)

app :: Term v -> Term v -> Term v
app (Lam _ t) u = subst0 =<< t u 
app t u = App t u

subst0 :: v :▹ Term v -> Term v
subst0 (Here x) = x
subst0 (There x) = Var x

{-
(>>=-) :: Term γ -> (γ -> Term δ) -> Term δ
Var x    >>=- θ = θ x
Lam nm f >>=- θ = with f $ \(_,t) -> Lam nm (\x -> t >>=- lift' x θ)
App t u  >>=- θ = App (t >>=- θ) (u >>=- θ)

lift' :: x -> v :=> w → (v :▹ Zero) :=> (w :▹ x)
lift' _ θ (There x) = wk (θ x)
lift' x _ (Here _) = var x 
-}

{-
data Ne v where
  Var' :: v → Ne v
  App' :: Ne v → No v → Ne v

data No v where
  Lam':: Name → (forall w. w → No (w :▹ v)) → No v
  Emb' :: Ne v -> No v

eval :: Term v -> No v
eval (Var x) = Emb' (Var' x)
eval (Lam n t) = Lam' n (eval . t)
eval (App t u) = app (eval t) (eval u)

instance Monad No where
  return = Emb' . Var'

app :: No v -> No v -> No v
app (Lam' _ t) u = yak =<< t u -- t u :: No (No v :▹ v)
app (Emb' t) u = Emb' $ App' t u

yak :: No v :▹ v -> No v
yak (There x) = x
yak (Here x) = Emb' (Var' x)
-}

-------------------
-- Size

sizeHO :: (a -> Int) -> Term a -> Int
sizeHO f (Var x) = f x
sizeHO f (Lam _ g) = 1 + sizeHO (extend f) (g 1)
sizeHO f (App t u) = 1 + sizeHO f t + sizeHO f u

sizeM :: Term Int -> Int
sizeM (Var x) = x
sizeM (Lam _ g) = 1 + sizeM (fmap untag (g 1))
sizeM (App t u) = 1 + sizeM t + sizeM u


sizeFO :: Term a -> Int
sizeFO (Var _) = 1
sizeFO (Lam _ g) = 1 + sizeFO (g ())
sizeFO (App t u) = 1 + sizeFO t + sizeFO u

sizeC :: Term Zero -> Int
sizeC = cata magic (\f -> 1 + f 1) (\a b -> 1 + a + b)

-----------------------
-- Can eta contract ?

untag :: a :▹ a -> a
untag (There x) = x 
untag (Here x) = x 

{-

(P)HOAS-style

canEta' :: Term Bool -> Bool
canEta' (Var b) = b
canEta' (App e1 e2) = canEta' e1 && canEta' e2
canEta' (Lam _ e') = canEta' (fmap untag $ e' True)


canEta :: Term Bool -> Bool
canEta (Lam _ e') = case fmap untag $ e' False of
  App e1 (Var False) -> canEta' e1
  _ -> False
canEta _ = False

canη :: Term Zero -> Bool
canη = canEta . fmap magic

-}


-- DeBrujn-style (?)
{-
openTerm :: Functor f => (forall w. w → f (v :▹ w)) -> v -> f v
openTerm b x = fmap (elim id (const x)) (b fresh)
  where fresh = error "cannot identify fresh variables!"
-}

data Ex f w where
  Ex :: v -> f (w :▹ v) -> Ex f w
    
with' :: (forall v. v → f (w :▹ v)) -> Ex f w
with' f = unpack f Ex

fresh :: Zero
fresh = error "cannot access free variables"

unpack :: (forall v. v → f (w :▹ v)) -> (forall v. v -> f (w :▹ v) -> a) -> a
unpack b k = k fresh (b fresh)
  where fresh = error "cannot query fresh variables!"

unpack2 :: (forall v. v → f (w :▹ v)) -> 
           (forall v. v → g (w :▹ v)) -> 
             
           (forall v. v → f (w :▹ v) -> 
                          g (w :▹ v) -> a) ->
           a 
unpack2 f f' k = k fresh (f fresh) (f' fresh)          
  where fresh = error "cannot query fresh variables!"

with :: (forall v. v → f (w :▹ v)) -> (forall v. v -> f (w :▹ v) -> a) -> a
with f k = case with' f of  Ex x t -> k x t


instance Eq w => Eq (w :▹ v) where
  Here _ == Here _ = True
  There x == There y = x == y
  _ == _ = False

  
memberOf :: Eq w => w -> Term w -> Bool
memberOf x t = x `elem` freeVars t

occursIn :: (Eq w, v :∈ w) => v -> Term w -> Bool
occursIn x t = lk x `elem` freeVars t

isOccurenceOf :: (Eq w, v :∈ w) => w -> v -> Bool
isOccurenceOf x y = x == lk y

rm :: [v :▹ a] -> [v]
rm xs = [x | There x <- xs]

freeVars :: Term w -> [w]
freeVars (Var x) = [x]
freeVars (Lam _ f) = unpack f $ \_ t -> rm $ freeVars t
freeVars (App f a) = freeVars f ++ freeVars a

canEta :: Term Zero -> Bool
canEta (Lam _ e) = case with' e of
  Ex x (App e1 (Var y)) -> lk x == y && not (lk x `memberOf` e1)
  _ -> False
canEta _ = False


-- recognizer of \x -> \y -> f x
recognize :: Term Zero -> Bool
recognize t0 = case t0 of 
    Lam _ f -> unpack f $ \x t1 -> case t1 of
      Lam _ g -> unpack g $ \y t2 -> case t2 of
        (App func (Var arg)) -> arg == lk x && not (lk x `memberOf` func)
        _ -> False   
      _ -> False   
    _ -> False   

-- recognizer of \x -> \y -> f x
recognize' :: Term Zero -> Bool
recognize' t0 = case t0 of 
    Lam _ f -> case with' f of
      Ex x (Lam _ g) -> case with' g of 
        Ex y (App func (Var arg)) -> arg == lk x && not (lk x `memberOf` func)
        _ -> False   
      _ -> False   
    _ -> False   

-------------
-- CPS

data Primop v :: * where 
--  Tru' :: Primop v
--  Fals' :: Primop v
  Var' :: v -> Primop v
  Abs' :: (∀ w. w -> Term' (v :▹ w)) -> Primop v
  (:-) :: v -> v -> Primop v  -- Pair
  Π1   :: v -> Primop v
  Π2   :: v -> Primop v


data Term' v where
  Halt' :: v -> Term' v
  App'  :: v -> v -> Term' v
  Let   :: Primop v -> (∀ w. w -> Term' (v :▹ w)) -> Term' v
  
instance Functor Term' where 
  

mapu :: (u -> u') -> (v -> v') -> (u :▹ v) -> (u' :▹ v')
mapu f g (There x) = There (f x)
mapu f g (Here x) = Here (g x)

instance Traversable Term where
  traverse f (Var x) =
    Var <$> f x
  traverse f (App t u) =
    App <$> traverse f t <*> traverse f u
  traverse f (Lam nm b) = lam' nm () <$> 
      traverse (traverseu f pure) (b ())

type Binding f a = forall b. b -> f (a ∪ b)

lam' :: Name → v -> Term (w :▹ v) → Term w
lam' nm x t = Lam nm (pack x t)


pack :: Functor f => v -> f (a ∪ v) -> Binding f a
pack _ t x = fmap (mapu id (const x)) t

traverseu :: Applicative f => (a -> f a') -> (b -> f b') ->
                              a ∪ b -> f (a' ∪ b')
traverseu f _ (There x) = There <$> f x
traverseu _ g (Here  x) = Here  <$> g x

fv' :: Term a -> [a]
fv' = toList

memberOf' :: Eq a => a -> Term a -> Bool
x `memberOf'` t = getAny $ foldMap (Any . (==x)) t

type Succ a = a ∪ ()

{-
instance Applicative ((∪) ()) where
  pure = Here
  Here f <*> Here x = Here (f x)
  _     <*> _     = There ()

instance Monad ((∪) ()) where
  return = Here
  Here x >>= f = f x
  There _ >>= _ = There ()
-}

-------------
-- α-eq

type Cmp a b = a -> b -> Bool

succCmp :: Cmp a b -> Cmp (Succ a) (Succ b)
succCmp f (There x)  (There y)  = f x y
succCmp _ (Here ()) (Here ()) = True
succCmp _ _        _        = False

cmpTerm :: Cmp a b -> Cmp (Term a) (Term b)
cmpTerm cmp (Var x1) (Var x2) = cmp x1 x2
cmpTerm cmp (App t1 u1) (App t2 u2) =
  cmpTerm cmp t1 t2 && cmpTerm cmp u1 u2
cmpTerm cmp (Lam _ f1) (Lam _ f2) =
  cmpTerm (succCmp cmp) (f1 ()) (f2 ())
cmpTerm _ _ _ = False




instance Eq a => Eq (Term a) where
  -- (==) = cmpTerm (==)
  Var x == Var x' = x == x'
  Lam _ g == Lam _ g' = unpack2 g g' $ \_ t t' -> t == t'
  App t u == App t' u' = t == t' && u == u'        



close :: Term (Succ a) -> Maybe (Term a)
close = traverse succToMaybe

succToMaybe :: Succ a -> Maybe a
succToMaybe (There a) = Just a
succToMaybe (Here _) = Nothing

canη' :: Eq a => Term a -> Bool
canη' (Lam _ t)
  | App u (Var (Here ())) <- t ()
    = not (Here () `memberOf` u)
canη' _ = False

ηred :: Term a -> Term a
ηred (Lam _ t)
  | App u (Var (Here ())) <- t ()
  , Just u' <- close u
  = u'
ηred t = t

ηexp :: Term a -> Term a
ηexp t = Lam "x" $ \x-> App (wk t) (var x)

instance Foldable Term where
  foldMap = foldMapDefault

  
spliceAbs :: ∀ v   .
             (forall w. w  → Term' (v :▹ w) ) -> 
             (∀ w. w  → Term' (v :▹ w) ) -> 
             forall w. w  → Term' (v :▹ w) 
spliceAbs e' e2 x = splice (e' x) (\ x₁ → wk (e2 x₁))

-- in e1, substitude Halt' by an arbitrary continuation e2
splice :: forall v  .
         Term' v  ->
         (∀ w. w  -> Term' (v :▹ w) ) -> 
         Term' v 
splice (Halt' v) e2 =  fmap untag (e2 v)
splice (App' f x) e2 = App' f x
splice (Let p e') e2 = Let (splicePrim p e2)  ( spliceAbs e' e2 )

splicePrim :: forall v. Primop v  ->  (∀ w. w  -> Term' (v :▹ w) ) -> Primop v 
splicePrim (Abs' e) e2 = Abs' (spliceAbs e e2)
--splicePrim Tru' e2 = Tru'
--splicePrim Fals' e2 = Fals'
splicePrim (Var' v) e2 = Var' v
splicePrim (y :- y') e2 = y :- y'
splicePrim (Π1 y) e2 = Π1 y
splicePrim (Π2 y) e2 = Π2 y  

cps :: Term v -> Term' v
-- cps Tru = Let Tru' (Halt' . There)
-- cps Fals = Let Fals' (Halt' . There) 
cps (Var v) = Halt' v
cps (App e1 e2) = splice (cps e1) $ \ f -> 
                      splice (wk (cps e2)) $ \ x →
                      Let (Abs' (\x -> Halt' (lk x))) $ \k →
                      Let (lk x :- lk k)    $ \p ->
                      App' (lk f) (lk p)
                      
cps (Lam _ e') =  Let (Abs' $ \p -> Let (Π1 (lk  p)) $ \x -> 
                                    Let (Π2 (lk p)) $ \k ->
                                    splice (wk (cps (e' x))) $ \r -> 
                                    App' (lk k) (lk r))
                      (\x -> Halt' (lk x))
                 



class x :∈ γ where
  lk :: x -> γ
  
instance x :∈ (γ :▹ x) where
  lk = Here
  
instance (x :∈ γ) => x :∈ (γ :▹ y) where
  lk = There . lk


class a :< b where
  inj :: a → b

instance a :< a where inj = id

instance Zero :< a where inj = magic

instance (γ :< δ) => (γ :▹ v) :< (δ :▹ v) where  inj = mapu inj id

instance (a :< c) => a :< (c :▹ b) where
  inj = There . inj

instance Functor ((:▹) a) where
  fmap _ (There x) = There x
  fmap f (Here x) = Here (f x)

testMe = freeVars ((Lam (Name "x") (\x -> App (var x) (var 'c'))) :: Term (a :▹ Char))
       
         
-----------------------------
-- Krivine Abstract Machine
-- (A call-by-name lambda-calculus abstract machine, sec. 1)

data Env w' w where -- input (w) and output (w') contexts
  Cons :: v -> Closure w -> Env w' w -> Env (w' :▹ v) w
  Nil :: Env w w 
  
look :: w' -> Env w' w -> Closure w
look = undefined
  
data Closure w where
  C :: Term w' -> Env w' w -> Closure w
  
type Stack w = [Closure w]  
  
kam :: Closure w -> Stack w -> Maybe (Closure w,Stack w)
kam (C (Lam n f) ρ) (u:s) = unpack f $ \ x t -> Just (C t (Cons x u ρ), s)
kam (C (App t u) ρ) s    = Just (C t ρ,C u ρ:s)
kam (C (Var x)   ρ) s    = Just (look x ρ,  s)
kam _ _ = Nothing

-------------------
-- Closure conversion 
-- following Guillemette&Monnier, A Type-Preserving Closure Conversion in Haskell, fig 2.

instance Functor LC where
  fmap f t = t >>= return . f

instance Monad LC where
  return = VarC
  
data LC w where
  VarC :: w -> LC w
  Closure :: (forall vx venv. vx -> venv -> LC (Zero :▹ venv :▹ vx)) -> -- ^ code
             LC w -> -- ^ env
             LC w
  LetOpen :: LC w -> (forall vf venv. vf -> venv -> LC (w :▹ vf :▹ venv)) -> LC w
  Tuple :: [LC w] -> LC w
  Index :: w -> Int -> LC w
  AppC :: LC w -> LC w -> LC w
 
cc :: forall w. Eq w => Term w -> LC w  
cc (Var x) = VarC x
cc (Lam _ f) = unpack f $ \x e -> 
  let yn = nub $ rm $ freeVars e 
      
  in Closure (\x' env -> subst (\z -> case z of
                                             Here _ -> var x' -- x becomes x'
                                             There w -> fmap There (Index (lk env) (fromJust $ elemIndex w yn))
                                                        -- other free vars are looked up in the env.
                                             -- unfortunately wk fails here.
                                         ) (cc e)) 
             (Tuple $ map VarC yn)
cc (App e1 e2) = LetOpen (cc e1) (\xf xenv -> (var xf `AppC` wk (cc e2)) `AppC` var xenv)

-- Possibly nicer version.
cc' :: forall w. Eq w => Term w -> LC w  
cc' (Var x) = VarC x
cc' t0@(Lam _ f) = 
  let yn = nub $ freeVars t0
  in Closure (\x env -> subst (lift (\w -> (Index (lk env) (fromJust $ elemIndex w yn))))
                                           (cc' (f x)))
             (Tuple $ map VarC yn)
cc' (App e1 e2) = LetOpen (cc' e1) (\xf xenv -> (var xf `AppC` wk (cc' e2)) `AppC` var xenv)


-----------------------
-- 


-- -}
-- -}
-- -}
-- -}
-- -}

