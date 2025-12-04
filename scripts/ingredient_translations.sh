#!/bin/bash

# Dictionnaire de traductions des ingrédients (anglais -> français/espagnol)
# Utilisé par test-recipes.sh pour afficher les traductions attendues

# Traductions anglais -> français
declare -A INGREDIENT_TRANSLATIONS_FR=(
    # Viandes
    ["chicken"]="Poulet"
    ["beef"]="Bœuf"
    ["pork"]="Porc"
    ["lamb"]="Agneau"
    ["turkey"]="Dinde"
    ["duck"]="Canard"
    ["steak"]="Steak"
    ["mince"]="Viande hachée"
    ["ground beef"]="Bœuf haché"
    ["bacon"]="Bacon"
    ["sausage"]="Saucisse"
    ["lamb mince"]="Agneau haché"
    
    # Poissons
    ["salmon"]="Saumon"
    ["tuna"]="Thon"
    ["cod"]="Morue"
    ["trout"]="Truite"
    ["mackerel"]="Maquereau"
    ["fish"]="Poisson"
    
    # Légumes
    ["tomato"]="Tomate"
    ["tomatoes"]="Tomates"
    ["onion"]="Oignon"
    ["onions"]="Oignons"
    ["garlic"]="Ail"
    ["carrot"]="Carotte"
    ["carrots"]="Carottes"
    ["potato"]="Pomme de terre"
    ["potatoes"]="Pommes de terre"
    ["pepper"]="Poivron"
    ["peppers"]="Poivrons"
    ["bell pepper"]="Poivron"
    ["zucchini"]="Courgette"
    ["courgette"]="Courgette"
    ["eggplant"]="Aubergine"
    ["aubergine"]="Aubergine"
    ["lettuce"]="Laitue"
    ["spinach"]="Épinards"
    ["cucumber"]="Concombre"
    ["mushroom"]="Champignon"
    ["mushrooms"]="Champignons"
    ["broccoli"]="Brocoli"
    ["cauliflower"]="Chou-fleur"
    ["cabbage"]="Chou"
    ["celery"]="Céleri"
    ["leek"]="Poireau"
    ["asparagus"]="Asperges"
    ["fennel"]="Fenouil"
    ["fennel bulb"]="Boule de fenouil"
    
    # Fruits
    ["apple"]="Pomme"
    ["apples"]="Pommes"
    ["banana"]="Banane"
    ["bananas"]="Bananes"
    ["orange"]="Orange"
    ["oranges"]="Oranges"
    ["lemon"]="Citron"
    ["lemons"]="Citrons"
    ["lime"]="Citron vert"
    ["strawberry"]="Fraise"
    ["strawberries"]="Fraises"
    ["blueberry"]="Myrtille"
    ["blueberries"]="Myrtilles"
    ["raspberry"]="Framboise"
    ["raspberries"]="Framboises"
    
    # Produits laitiers
    ["milk"]="Lait"
    ["cheese"]="Fromage"
    ["butter"]="Beurre"
    ["cream"]="Crème"
    ["yogurt"]="Yaourt"
    ["yoghurt"]="Yaourt"
    ["sour cream"]="Crème fraîche"
    ["cottage cheese"]="Fromage blanc"
    
    # Céréales et féculents
    ["rice"]="Riz"
    ["basmati rice"]="Riz basmati"
    ["pasta"]="Pâtes"
    ["spaghetti"]="Spaghettis"
    ["noodles"]="Nouilles"
    ["bread"]="Pain"
    ["flour"]="Farine"
    ["wheat flour"]="Farine de blé"
    ["corn"]="Maïs"
    ["quinoa"]="Quinoa"
    ["couscous"]="Couscous"
    ["bulgur"]="Boulgour"
    ["oats"]="Avoine"
    ["barley"]="Orge"
    
    # Épices et herbes
    ["salt"]="Sel"
    ["pepper"]="Poivre"
    ["black pepper"]="Poivre noir"
    ["paprika"]="Paprika"
    ["cumin"]="Cumin"
    ["coriander"]="Coriandre"
    ["parsley"]="Persil"
    ["chopped parsley"]="Persil haché"
    ["basil"]="Basilic"
    ["oregano"]="Origan"
    ["thyme"]="Thym"
    ["rosemary"]="Romarin"
    ["sage"]="Sauge"
    ["mint"]="Menthe"
    ["dill"]="Aneth"
    ["chives"]="Ciboulette"
    ["bay leaf"]="Feuille de laurier"
    ["bay leaves"]="Feuilles de laurier"
    ["ginger"]="Gingembre"
    ["cinnamon"]="Cannelle"
    ["clove"]="Clou de girofle"
    ["cloves"]="Clous de girofle"
    ["ground clove"]="Clou de girofle moulu"
    ["ground cinnamon"]="Cannelle moulue"
    
    # Huiles et vinaigres
    ["oil"]="Huile"
    ["olive oil"]="Huile d'olive"
    ["vegetable oil"]="Huile végétale"
    ["sunflower oil"]="Huile de tournesol"
    ["vinegar"]="Vinaigre"
    ["balsamic vinegar"]="Vinaigre balsamique"
    ["white vinegar"]="Vinaigre blanc"
    ["apple cider vinegar"]="Vinaigre de cidre"
    
    # Autres
    ["egg"]="Œuf"
    ["eggs"]="Œufs"
    ["sugar"]="Sucre"
    ["caster sugar"]="Sucre en poudre"
    ["brown sugar"]="Sucre roux"
    ["honey"]="Miel"
    ["vanilla"]="Vanille"
    ["vanilla extract"]="Extrait de vanille"
    ["nutmeg"]="Muscade"
    ["turmeric"]="Curcuma"
    ["curry"]="Curry"
    ["chili"]="Piment"
    ["chili pepper"]="Piment"
    ["chili powder"]="Piment en poudre"
    ["soy sauce"]="Sauce soja"
    ["worcestershire sauce"]="Sauce Worcestershire"
    ["tomato paste"]="Concentré de tomate"
    ["tomato sauce"]="Sauce tomate"
    ["chicken broth"]="Bouillon de poulet"
    ["beef broth"]="Bouillon de bœuf"
    ["vegetable broth"]="Bouillon de légumes"
    ["stock"]="Bouillon"
    ["water"]="Eau"
    ["wine"]="Vin"
    ["white wine"]="Vin blanc"
    ["red wine"]="Vin rouge"
    ["lemon juice"]="Jus de citron"
    ["vine leaves"]="Feuilles de vigne"
)

# Traductions anglais -> espagnol
declare -A INGREDIENT_TRANSLATIONS_ES=(
    # Viandes
    ["chicken"]="Pollo"
    ["beef"]="Carne de res"
    ["pork"]="Cerdo"
    ["lamb"]="Cordero"
    ["turkey"]="Pavo"
    ["duck"]="Pato"
    ["steak"]="Bistec"
    ["mince"]="Carne molida"
    ["ground beef"]="Carne molida de res"
    ["bacon"]="Tocino"
    ["sausage"]="Salchicha"
    ["lamb mince"]="Carne molida de cordero"
    
    # Poissons
    ["salmon"]="Salmón"
    ["tuna"]="Atún"
    ["cod"]="Bacalao"
    ["trout"]="Trucha"
    ["mackerel"]="Caballa"
    ["fish"]="Pescado"
    
    # Légumes
    ["tomato"]="Tomate"
    ["tomatoes"]="Tomates"
    ["onion"]="Cebolla"
    ["onions"]="Cebollas"
    ["garlic"]="Ajo"
    ["carrot"]="Zanahoria"
    ["carrots"]="Zanahorias"
    ["potato"]="Patata"
    ["potatoes"]="Patatas"
    ["pepper"]="Pimiento"
    ["peppers"]="Pimientos"
    ["bell pepper"]="Pimiento"
    ["zucchini"]="Calabacín"
    ["courgette"]="Calabacín"
    ["eggplant"]="Berenjena"
    ["aubergine"]="Berenjena"
    ["lettuce"]="Lechuga"
    ["spinach"]="Espinacas"
    ["cucumber"]="Pepino"
    ["mushroom"]="Champiñón"
    ["mushrooms"]="Champiñones"
    ["broccoli"]="Brócoli"
    ["cauliflower"]="Coliflor"
    ["cabbage"]="Repollo"
    ["celery"]="Apio"
    ["leek"]="Puerro"
    ["asparagus"]="Espárragos"
    ["fennel"]="Hinojo"
    ["fennel bulb"]="Bola de hinojo"
    
    # Fruits
    ["apple"]="Manzana"
    ["apples"]="Manzanas"
    ["banana"]="Plátano"
    ["bananas"]="Plátanos"
    ["orange"]="Naranja"
    ["oranges"]="Naranjas"
    ["lemon"]="Limón"
    ["lemons"]="Limones"
    ["lime"]="Lima"
    ["strawberry"]="Fresa"
    ["strawberries"]="Fresas"
    ["blueberry"]="Arándano"
    ["blueberries"]="Arándanos"
    ["raspberry"]="Frambuesa"
    ["raspberries"]="Frambuesas"
    
    # Produits laitiers
    ["milk"]="Leche"
    ["cheese"]="Queso"
    ["butter"]="Mantequilla"
    ["cream"]="Crema"
    ["yogurt"]="Yogur"
    ["yoghurt"]="Yogur"
    ["sour cream"]="Crema agria"
    ["cottage cheese"]="Requesón"
    
    # Céréales et féculents
    ["rice"]="Arroz"
    ["basmati rice"]="Arroz basmati"
    ["pasta"]="Pasta"
    ["spaghetti"]="Espaguetis"
    ["noodles"]="Fideos"
    ["bread"]="Pan"
    ["flour"]="Harina"
    ["wheat flour"]="Harina de trigo"
    ["corn"]="Maíz"
    ["quinoa"]="Quinoa"
    ["couscous"]="Cuscús"
    ["bulgur"]="Bulgur"
    ["oats"]="Avena"
    ["barley"]="Cebada"
    
    # Épices et herbes
    ["salt"]="Sal"
    ["pepper"]="Pimienta"
    ["black pepper"]="Pimienta negra"
    ["paprika"]="Pimentón"
    ["cumin"]="Comino"
    ["coriander"]="Cilantro"
    ["parsley"]="Perejil"
    ["chopped parsley"]="Perejil picado"
    ["basil"]="Albahaca"
    ["oregano"]="Orégano"
    ["thyme"]="Tomillo"
    ["rosemary"]="Romero"
    ["sage"]="Salvia"
    ["mint"]="Menta"
    ["dill"]="Eneldo"
    ["chives"]="Cebollino"
    ["bay leaf"]="Hoja de laurel"
    ["bay leaves"]="Hojas de laurel"
    ["ginger"]="Jengibre"
    ["cinnamon"]="Canela"
    ["clove"]="Clavo"
    ["cloves"]="Clavos"
    ["ground clove"]="Clavo molido"
    ["ground cinnamon"]="Canela molida"
    
    # Huiles et vinaigres
    ["oil"]="Aceite"
    ["olive oil"]="Aceite de oliva"
    ["vegetable oil"]="Aceite vegetal"
    ["sunflower oil"]="Aceite de girasol"
    ["vinegar"]="Vinagre"
    ["balsamic vinegar"]="Vinagre balsámico"
    ["white vinegar"]="Vinagre blanco"
    ["apple cider vinegar"]="Vinagre de sidra de manzana"
    
    # Autres
    ["egg"]="Huevo"
    ["eggs"]="Huevos"
    ["sugar"]="Azúcar"
    ["caster sugar"]="Azúcar glas"
    ["brown sugar"]="Azúcar moreno"
    ["honey"]="Miel"
    ["vanilla"]="Vainilla"
    ["vanilla extract"]="Extracto de vainilla"
    ["nutmeg"]="Nuez moscada"
    ["turmeric"]="Cúrcuma"
    ["curry"]="Curry"
    ["chili"]="Chile"
    ["chili pepper"]="Chile"
    ["chili powder"]="Chile en polvo"
    ["soy sauce"]="Salsa de soja"
    ["worcestershire sauce"]="Salsa Worcestershire"
    ["tomato paste"]="Pasta de tomate"
    ["tomato sauce"]="Salsa de tomate"
    ["chicken broth"]="Caldo de pollo"
    ["beef broth"]="Caldo de res"
    ["vegetable broth"]="Caldo de verduras"
    ["stock"]="Caldo"
    ["water"]="Agua"
    ["wine"]="Vino"
    ["white wine"]="Vino blanco"
    ["red wine"]="Vino tinto"
    ["lemon juice"]="Jugo de limón"
    ["vine leaves"]="Hojas de parra"
)

# Fonction pour obtenir la traduction d'un ingrédient
get_ingredient_translation() {
    local ingredient="$1"
    local lang="$2"
    local lower_ingredient=$(echo "$ingredient" | tr '[:upper:]' '[:lower:]' | xargs)
    
    case "$lang" in
        fr)
            # Chercher d'abord une correspondance exacte
            if [ -n "${INGREDIENT_TRANSLATIONS_FR[$lower_ingredient]}" ]; then
                echo "${INGREDIENT_TRANSLATIONS_FR[$lower_ingredient]}"
                return 0
            fi
            # Chercher une correspondance partielle
            for key in "${!INGREDIENT_TRANSLATIONS_FR[@]}"; do
                if [[ "$lower_ingredient" == *"$key"* ]] || [[ "$key" == *"$lower_ingredient"* ]]; then
                    echo "${INGREDIENT_TRANSLATIONS_FR[$key]}"
                    return 0
                fi
            done
            echo ""  # Pas de traduction trouvée
            ;;
        es)
            # Chercher d'abord une correspondance exacte
            if [ -n "${INGREDIENT_TRANSLATIONS_ES[$lower_ingredient]}" ]; then
                echo "${INGREDIENT_TRANSLATIONS_ES[$lower_ingredient]}"
                return 0
            fi
            # Chercher une correspondance partielle
            for key in "${!INGREDIENT_TRANSLATIONS_ES[@]}"; do
                if [[ "$lower_ingredient" == *"$key"* ]] || [[ "$key" == *"$lower_ingredient"* ]]; then
                    echo "${INGREDIENT_TRANSLATIONS_ES[$key]}"
                    return 0
                fi
            done
            echo ""  # Pas de traduction trouvée
            ;;
        *)
            echo ""  # Pas de traduction pour l'anglais
            ;;
    esac
}

