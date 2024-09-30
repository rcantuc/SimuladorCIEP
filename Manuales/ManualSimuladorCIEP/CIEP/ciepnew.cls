%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%            Templates CIEP            %%%
%%%         Autor: Ricardo Cantu         %%%
%%%         Version: Paquete 2023        %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{ciep}[2022/08/17 - Centro de Investigacion Economica y Presupuestaria, A.C.]





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% OPCIONES DE DOCUMENTOS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcommand\@tipodoc{1}
\DeclareOption{documento}{\renewcommand\@tipodoc{1}}

\newcommand\@prologo{0}
\DeclareOption{prologo}{\renewcommand\@prologo{1}}

\newcommand\@resumen{0}
\DeclareOption{resumen}{\renewcommand\@resumen{1}}

\newcommand\@acronimos{0}
\DeclareOption{acronimos}{\renewcommand\@acronimos{1}}

\newcommand\@nocuadros{0}
\DeclareOption{nocuadros}{\renewcommand\@nocuadros{1}}

\newcommand\@nofiguras{0}
\DeclareOption{nofiguras}{\renewcommand\@nofiguras{1}}

\newcommand\@noindice{0}
\DeclareOption{noindice}{\renewcommand\@noindice{1}}

\newcommand\@english{0}
\DeclareOption{english}{\renewcommand\@english{1}}

\newcommand\@noportada{0}
\DeclareOption{noportada}{\renewcommand\@noportada{1}}

\ProcessOptions\relax




\RequirePackage{blindtext}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1. TAMAÑO DE PAPEL Y GEOMETRIA %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\LoadClass[oneside,10pt,openleft]{memoir}
\setstocksize{252mm}{200mm}%A3{297mm}{210mm}				% Tamaño del papel a imprimir
\settrimmedsize{252mm}{200mm}{*}%{222mm}{200mm}{*}	 	% Tamaño después de cortar
\settypeblocksize{215mm}{125mm}{*}%{170mm}{120mm}{*}		% Tamaño del bloque de texto
\setlrmargins{5.5cm}{*}{*}%{*}{5.25cm}{*}					% Tamaño de márgenes left and right
\setulmargins{*}{*}{0.6180339888}%{0.6180339888}						% Tamaño de márgnees upper and lower
\setheadfoot{2\baselineskip}{2\baselineskip}				% Tamaño del headheight y footskip
\setheaderspaces{*}{.5cm}{0.6180339888}						% Tamaño del headdrop y headsep (y ratio)
\setfootins{.35cm}{.25cm}											% Separación de las notas al pie
\checkandfixthelayout
\fixpdflayout





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2. PAQUETES Y CONFIGURACIONES %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\RequirePackage[utf8]{inputenc}								% Inputs from keyboard
\RequirePackage[T1]{fontenc}									% Output font encoding (acentos)
%\RequirePackage[default,osfigures]{opensans}				% Font
\RequirePackage{fontspec}										% Font
	\setsansfont{Ubuntu}										% Ubuntu
	\setmainfont{Ubuntu Light}									% Open Sans
\RequirePackage{microtype} 									% Mejor caligrafía
\RequirePackage[hidelinks]{hyperref} 						% Links
\RequirePackage[natbibapa]{apacite}							% Bibliografía formato APA
%\RequirePackage[spanish]{cleveref}							% Referencias con ``figura'', ``tabla'', etc
\RequirePackage[fixlanguage]{babelbib}
	\selectbiblanguage{spanish}
\RequirePackage[spanish]{babel}								% Idioma: spanish
	\decimalpoint
\bibliographystyle{apacite}
\RequirePackage[usenames,dvipsnames,svgnames,table]{xcolor}	% Colores
	\definecolor{naranja}{RGB}{242,112,42}					% Naranja CIEP
	\definecolor{primario}{RGB}{242,112,42}					% Naranja CIEP
	\definecolor{naranjaclaro}{HTML}{ff874d}				% Naranja claro CIEP
	\definecolor{azul}{HTML}{2d353a}							% Negro-Azul CIEP
	\definecolor{secundario}{RGB}{52,70,78}					% Negro-Azul CIEP
	\definecolor{gris}{HTML}{999b9c}							% Gris claro
	\colorlet{grisclaro}{gris!10}								% Gris claro
	\definecolor{texto}{RGB}{52,70,78}						% Negro-Azul CIEP
	\color{azul}
\RequirePackage[all,defaultlines=1]{nowidow}				% Líneas huérfanas y viudas
\RequirePackage{url} 											% URL enabled
\RequirePackage[space]{grffile}								% Permitir espacios en nombres de archivos
\RequirePackage{hyphenat} 										% Eliminar guiones (palabras)
\RequirePackage{graphicx} 										% Incluir gráficas
	\ifdefined\maindoc
		\graphicspath{{CIEP/images/}{images/}}				% Directorio de las gráficas
	\else
		\graphicspath{{../CIEP/images/}{../images/}}		% Directorio de las gráficas
	\fi
\RequirePackage{amsmath,amsfonts,amsthm,amssymb}			% Formulas
\RequirePackage[most]{tcolorbox}								% Cuadros de color
	\tcbset{colback=white,colframe=white,fonttitle=\color{primario}\small,%
	fontupper=\color{azul},oversize,%
	left=.618\baselineskip,right=.618\baselineskip,top=.618\baselineskip,bottom=.618\baselineskip}
\RequirePackage{soul}											% Mejor subrayado
	\setul{1pt}{.4pt}											% Underline setting. 1pt below contents
\RequirePackage{fp}												% Operaciones matemáticas dentro de LaTeX
\RequirePackage{calc}											% Permite hacer cálculos en LaTeX
	\def\commatononei#1,#2{#1#2}
	\def\commatonone#1{\expandafter\commatononei#1}		% Quitar comas a los números para los cálculos
\RequirePackage[printonlyused]{acronym}						% Acrónimos
	\feetbelowfloat
\RequirePackage{longtable}
%\RequirePackage{setspace}
\RequirePackage{titlesec}										% Formato Secciones, Subsecciones, etc.
\RequirePackage{titletoc}										% Formato Índice
\RequirePackage{pagecolor}										% Color de la página
\RequirePackage{afterpage}										% Detectar fin de páginas
\RequirePackage{marginnote}
	\edef\marginnotetextwidth{3.5cm}

\RequirePackage{tikz}											% Dibujar y posicionar
	\usetikzlibrary{shapes, shapes.geometric, arrows, positioning, arrows.meta}
	\tikzstyle{arrow} = [thick,>=stealth,->]
\linespread{1.2}													% Espacio entre líneas
\setlength{\parindent}{0cm}									% Sangría
\setlength{\parskip}{.309\baselineskip}						% Espacio después de párrafos
\setlength\heavyrulewidth{0.3ex}								% Toprule and bottomrule

\let\emph\relax
\DeclareTextFontCommand{\emph}{\color{primario}\bfseries\sffamily}
%\renewcommand{\emph}[1]{{\color{naranja}\bfseries\textsf{#1}}}


\DeclareSymbolFont{extraup}{U}{zavm}{m}{n}
\DeclareMathSymbol{\varheart}{\mathalpha}{extraup}{86}
\DeclareMathSymbol{\vardiamond}{\mathalpha}{extraup}{87}
\newcommand{\heart}{\ensuremath\varheart}

\counterwithin{figure}{chapter}
\counterwithin{table}{chapter}





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 3. TÍTULO, SUBTÍTULO, AUTORES, ETC. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\def\titlesize#1{\gdef\title@size{#1}}					% Tamaño del titulo
\def\subtitle#1{\gdef\@subtitle{#1}}						% Subtitulo
\def\subtitlesize#1{\gdef\subtitle@size{#1}}			% Tamaño del subtitulo
\def\iniciociep#1{\gdef\@iniciociep{#1}}

\def\authorb#1{\gdef\@authorb{#1}}						% Autor B
\def\authorc#1{\gdef\@authorc{#1}}						% Autor C
\def\authord#1{\gdef\@authord{#1}}						% Autor D
\def\authore#1{\gdef\@authore{#1}}						% Autor E
\def\authorf#1{\gdef\@authorf{#1}}						% Autor F
\def\authorg#1{\gdef\@authorg{#1}}						% Autor G
\def\authorh#1{\gdef\@authorh{#1}}						% Autor H

\def\chapterauthor#1{\gdef\@chapterauthor{#1}}		% Autor H
\chapterauthor{CIEP}

\def\email#1{\gdef\@email{#1}} 							% Email A
\def\emailb#1{\gdef\@emailb{#1}}							% Email B
\def\emailc#1{\gdef\@emailc{#1}}							% Email C
\def\emaild#1{\gdef\@emaild{#1}}							% Email D
\def\emaile#1{\gdef\@emaile{#1}}							% Email E
\def\emailf#1{\gdef\@emailf{#1}}							% Email F
\def\emailg#1{\gdef\@emailg{#1}}							% Email G
\def\emailh#1{\gdef\@emailh{#1}}							% Email H

\def\phone#1{\gdef\@phone{#1}} 							% Phone A
\def\phoneb#1{\gdef\@phoneb{#1}}							% Phone B
\def\phonec#1{\gdef\@phonec{#1}}							% Phone C

\def\isbn#1{\gdef\@isbn{#1}}								% ISBN

\def\equationimage#1{\gdef\@equationimage{#1}}		% Ecuación de la parte
\def\partimage#1{\gdef\@partimage{#1}}					% Imagen de la parte
\def\partimageb#1{\gdef\@partimageb{#1}}				% Imagen de la parte

\newcommand{\HorRule}{\color{gris}\rule{.33\textwidth}{.4pt}}
\newcommand{\HorRuleW}{\color{white}\rule{.33\textwidth}{.4pt}}





%%%%%%%%%%%%%%%%%%
%%% 4. PORTADA %%%
%%%%%%%%%%%%%%%%%%
\renewcommand{\maketitle}{%
	\frontmatter


	%%%%%%%%%%%%%%%%%%%%%%%%
	%% Imagen predefinida %%
	%%%%%%%%%%%%%%%%%%%%%%%%
	\ifnum\@noportada=0
		\thispagestyle{empty}
		\begin{tikzpicture}[remember picture,overlay]
			\node[opacity=0.99,anchor=center,xshift=0\paperwidth] at (current page.center) 
				{\includegraphics[width=\paperwidth]{portada}};
		\end{tikzpicture}
		\clearpage
	\fi

	%%%%%%%%%%%%%%%%%%%%%%%
	%% Diseño de portada %%
	%%%%%%%%%%%%%%%%%%%%%%%
	\thispagestyle{empty}
	\begin{tikzpicture}[remember picture,overlay]
		\node[anchor=north,yshift=-.1\textheight] at (current page.north) {
			%\HorRule\hspace{.045\textwidth}
				\raisebox{-19pt}{\includegraphics[width=.618\textwidth]{CIEPlogo}}\hspace{.015\textwidth}\HorRuleW\HorRuleW
		};
		%\node[anchor=north,yshift=-.155\textheight] at (current page.north) {\acl{CIEP}};
		\node[anchor=south,yshift=.025\textheight] at (current page.south) {\titulocuadro};
	\end{tikzpicture}
	\clearpage

	%%%%%%%%%%%%
	%% Índice %%
	%%%%%%%%%%%%
	\chapterstyle{Indexes}
	\pagestyle{ciepFront}
	\equationimage{roseta-color}
	\partimage{roseta-color}
	\ifnum\@noindice=0
		\nohyphens{\tableofcontents*}
	\fi

	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Resumen Ejecutivo y Prólogo %%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	\chapterstyle{Front}
	\ifdefined\maindoc
		\ifnum\@prologo=1
			\input{Prólogo/prologo}\clearpage
		\fi
		\ifnum\@resumen=1
			\input{Prólogo/resumen}\clearpage
			\input{Prólogo/intro}\clearpage
		\fi
	\fi

	%%%%%%%%%%%%%%%%%
	%% Main matter %%
	%%%%%%%%%%%%%%%%%
	\mainmatter
	\pagestyle{ciep}
	\chapterstyle{ciep}
	\setcounter{secnumdepth}{2}									% Profundidad del índice (1 = section, 0 = chapter, -1 = part)
	\setcounter{tocdepth}{1}
}
\newcommand{\titulocuadro}{%
	\begin{minipage}[t][.618\paperheight][c]{.8\paperwidth}
		%\centering
		\title@size\nohyphens{
		\color{azul}{\bfseries\@title\par}
		\ifdefined\@subtitle			
			\vspace{.618\baselineskip}
			\parbox[c]{\textwidth}{%
				%\centering
				\ifdefined\subtitle@size\subtitle@size\fi%
				\color{naranja}{\@subtitle}%
			}
		\fi}
	\par\vspace{2.618\baselineskip}%
	\parbox[t][]{\textwidth}{
			%\centering
			\parbox[t]{\textwidth}{
				\color{azul}%\centering
				\normalsize\@author\par}
		}%
	\vfill%
	\parbox[c]{\textwidth}{%
	\begin{tcolorbox}[colback=white,colframe=white]
		\color{azul}\small
		%Somos un \textbf{centro de investigación de la sociedad civil}, sin fines de lucro y apartidista, \\ que contribuye a la comprensión de la economía y finanzas públicas en México, \\ mediante herramientas y análisis accesibles y técnicamente sólidos, \\ \textbf{para lograr una sociedad  más informada y participativa}, mejorar las políticas públicas y \\ construir un sistema fiscal \textbf{en beneficio de las generaciones presentes y futuras}.
		%\textbf{ISBN}: \@isbn\ (PDF)\\[.618\baselineskip]
		\scriptsize
		\acf{CIEP}\\
		Puebla 151, Letra O, Roma Norte, Cuauhtémoc, C.P. 06700,\\
		Ciudad de México, México. Tel: (55) 53.40.86.88 \\[.618\baselineskip]
		\ifdefined\@email\href{mailto:\@email}{\small \@email}\par{\small\href{https://ciep.mx}{https://ciep.mx}}\fi \\[.618\baselineskip]
		\@date\\[.618\baselineskip]
		%Las opiniones expresadas en esta obra son de exclusiva responsabilidad de sus autores y no representan la posición oficial del \acl{CIEP}\\[.618\baselineskip]
		%Prohibida la reproducción total o parcial de los contenidos de esta obra por cualquier medio o procedimiento, sin autorización escrita o expresa del \acl{CIEP}\\[.618\baselineskip]
		%Hecho en México.
	\end{tcolorbox}
			}
	\end{minipage}
}





%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 5. HEADERS Y FOOTERS %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\setpnumwidth{.65cm}
\makeoddhead{plain}%
	{}%
	{}%
	{}	
\makeevenhead{plain}%
	{}%
	{}%
	{}
\makeevenfoot{plain}%
	{}%
	{\color{primario}\footnotesize\bfseries\thepage}%
	{}
	
\makeoddfoot{plain}%
	{}%
	{\color{primario}\footnotesize\bfseries\thepage}%
	{}

\makepagestyle{ciep}
\makepsmarks{ciep}{}{
	\createmark {part} {both} {shownumber}{}{. \ }
	\createmark {chapter} {both} {shownumber}{}{. \ }
	\createmark {section} {right}{shownumber}{} {. \ }
	\createmark {subsection} {right}{shownumber}{} {. \ }
	\createmark {subsubsection}{right}{shownumber}{} {. \ }
	\createplainmark {toc} {right} {\contentsname}
	\createplainmark {lof} {right} {\listfigurename}
	\createplainmark {lot} {right} {\listtablename}
	\createplainmark {bib} {right} {\bibname}
	\createplainmark {index} {right} {\indexname}
	\createplainmark {glossary} {right} {\glossaryname}
}
\addtopsmarks{ciep}{%
	\nouppercaseheads % added at the beginning
	\createmark{chapter}{both}{nonumber}{}{. \space}
	\createmark{section}{right}{nonumber}{}{. \space}
}

\makepagestyle{ciepFront}
\addtopsmarks{ciepFront}{%
	\nouppercaseheads % added at the beginning
	\createmark{chapter}{both}{nonumber}{}{. \space}
	\createmark{section}{right}{nonumber}{}{. \space}
}

\makeoddhead{ciep}%
	{\footnotesize\nohyphens{\color{azul}{\leftmark}\par\color{primario}\righttopmark}
	\begin{tikzpicture}[remember picture,overlay]
		%\node[anchor=center,xshift=3.375cm,yshift=-5.25\baselineskip] at (current page.north west) {\includegraphics[height=1.618\baselineskip]{\@equationimage}};
	\end{tikzpicture}}%
	{}%
	{\raisebox{\baselineskip}{\color{azul}\scriptsize\bfseries}}
\makeoddfoot{ciep}%
	{}%
	{\color{primario}\footnotesize\bfseries\thepage}%
	{}
\makeevenfoot{ciep}%
	{}%
	{\color{primario}\footnotesize\bfseries\thepage}%
	{}	

\makeoddhead{ciepFront}%
	{\footnotesize\nohyphens{\color{azul}\textbf{\@title}\par\scriptsize\color{naranja}\@subtitle}
	\begin{tikzpicture}[remember picture,overlay]
		%\node[anchor=center,xshift=3.375cm,yshift=-5.25\baselineskip] at (current page.north west) {\includegraphics[height=1.618\baselineskip]{\@equationimage}};
	\end{tikzpicture}}%
	{}%
	{\raisebox{\baselineskip}{\color{azul}\scriptsize\bfseries}}
\makeoddfoot{ciepFront}%
	{}%
	{\color{naranja}\footnotesize\bfseries\thepage}%
	{}
\makeevenfoot{ciepFront}%
	{}%
	{\color{naranja}\footnotesize\bfseries\thepage}%
	{}


\providecommand*{\righttopmark}{\expandafter\@rightmark\topmark\@empty\@empty}





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 6. PARTES, CAPÍTULOS, SECCIONES, SUBSECCIONES, PÁRRAFOS... %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%
% PARTES %
\renewcommand{\@setuppart}{%
	\cleartoevenpage[\thispagestyle{empty}]
	\thispagestyle{empty}%\newpagecolor{naranja}
	%\begin{tikzpicture}[remember picture,overlay]
		%\node[anchor=center,xshift=1pt,yshift=1pt,pattern=mydots,pattern color=azul,minimum height=\paperheight,minimum width=\paperwidth] at (current page.center) {};
		%\node[anchor=center,xshift=0cm,yshift=0cm,opacity=1] at (current page.center) {
		%	\includegraphics[height=\paperheight]{\@partimage}
		%};
	%\end{tikzpicture}
  \if@openright
    \cleardoublepage
  \else
    \clearpage
  \fi
  \thispagestyle{part}%
  \if@twocolumn
    \onecolumn
    \@tempswatrue
  \else
    \@tempswafalse
  \fi
  \beforepartskip}
\renewcommand*{\partnamefont}{\centering\color{azul}\bfseries\MakeUppercase}
\renewcommand*{\partnumfont}{\centering\color{azul}\bfseries\MakeUppercase}
\renewcommand*{\parttitlefont}{\centering\color{azul}\fontsize{25}{25}\bfseries\MakeUppercase}
\renewcommand*{\beforepartskip}{%\newpagecolor{azul}\afterpage{\restorepagecolor}
	\thispagestyle{empty}\null\vfil}
\renewcommand*{\afterpartskip}{\partpageend}
\renewcommand{\partpageend}{
	%\color{naranja}\rule{0.381966012\textwidth}{2pt}
	\vfil\clearpage\newpagecolor{white}\normalsize\normalfont\flushleftright
}
\def\parttitle#1{\gdef\@parttitle{#1}}				% Título de la parte
\def\partdesc#1{\gdef\@partdesc{#1}}					% Descripción de la parte
\partdesc{}
\long\def\@part[#1]#2{%
  \parttitle{#1}
  \M@gettitle{#1}%
  \def\f@rtoc{#1}%
  \@nameuse{part@f@rtoc@before@write@hook}%
  \phantomsection
  \mempreaddparttotochook
  \ifnum \c@secnumdepth >-2\relax
    \refstepcounter{part}%
    \addcontentsline{toc}{part}%
      {\protect\partnumberline{\thepart}\f@rtoc}%
    \mempartinfo{\thepart}{\f@rtoc}{#2}%
  \else
    \addcontentsline{toc}{part}{\f@rtoc}%
    \mempartinfo{}{\f@rtoc}{#2}%
  \fi
  \mempostaddparttotochook
  \partmark{#1}%
  {\centering
   \interlinepenalty \@M
   \parskip\z@
   \normalfont
	\begin{tikzpicture}[remember picture,overlay]
		%\node[anchor=center,xshift=0pt,yshift=0pt] at (current page.center) {
		%	\includegraphics[width=\paperwidth]{Subportada_\thepart}
		%};
		\node[anchor=center,xshift=0pt,yshift=.075\paperheight] at (current page.center) {
			\parbox[c][][c]{.6180339888\paperwidth}{
				\ifnum \c@secnumdepth >-2\relax
					\printpartname \partnamenum \printpartnum
					\midpartskip
				\fi
			}\par
		};
		\node[anchor=center,xshift=0cm,yshift=.035\paperheight] at (current page.center) {
			\parbox[c][][c]{.75\paperwidth}{%
				\printparttitle{#2}
			}
		};
		%\node[anchor=center,xshift=0cm,yshift=6.2122cm] at (current page.south) {
		%	\parbox[c][][c]{.7\paperwidth}{%
		%		\@partdesc
		%	}
		%};
	\end{tikzpicture}
   \par}%
  \@endpart}

% ÍNDICE (PARTES) %
\newlength{\mylenb}% New length to use when setting indentation 
\settowidth{\mylenb}{\textbf{VIII}}% Sets mylen to width of word “Contents”, large and bold 

\renewcommand*{\cftpartfont}{\color{azul}\bfseries\Large}
\renewcommand*{\cftpartpresnum}{\color{azul}\Large\hfil}
\renewcommand*{\cftpartaftersnum}{\color{azul}}	
\renewcommand*{\cftpartaftersnumb}{\hspace{6pt}}	
\renewcommand*{\cftpartnumwidth}{\mylenb}
\renewcommand*{\cftpartleader}{\hspace{.25cm}\color{naranja}\hrulefill\hspace{.25cm}}
\renewcommand*{\cftpartformatpnum}{\color{azul}\bfseries\Large}

\setlength{\cftpartindent}{0cm}
\setlength{\cftbeforepartskip}{1\baselineskip}


%%%%%%%%%%%%%	
% CAPÍTULOS %
\addto\captionsspanish{
	\renewcommand{\contentsname}{\textbf{Índice general}}
}

\makechapterstyle{ciep}{%
	\setlength{\beforechapskip}{-3\baselineskip}
	\setlength{\afterchapskip}{\baselineskip}
	\renewcommand*{\chapnumfont}{}
	\settowidth{\chapindent}{\chapnumfont 999}
	\renewcommand*{\printchaptername}{}
	\renewcommand*{\chapternamenum}{}
	\renewcommand*{\afterchapternum}{}
	\renewcommand*{\printchaptertitle}[1]{%
		\parbox[c][8\baselineskip][c]{\textwidth}{
			{\raggedright\fontsize{25}{25}\selectfont\color{azul}{\sffamily\nohyphens{##1}}\par}
			\vspace{.618\baselineskip}
			%por \@chapterauthor
		}%
	}
	\renewcommand*{\printchapternum}{%
		\begin{tikzpicture}[remember picture,overlay]
			\node[anchor=north west,fill=primario,xshift=-10pt,yshift=-2.5\baselineskip,minimum width=5cm,minimum height=8\baselineskip,rounded corners=10] 
				at (current page.north west) {\parbox{5cm}{\raggedleft\textcolor{white}{\sffamily\huge\textbf{Capítulo \thechapter\hspace{30pt}}}}};
		\end{tikzpicture}
	}
}

\makechapterstyle{Front}{%
	\setlength{\beforechapskip}{-3\baselineskip}
	\setlength{\afterchapskip}{\baselineskip}
	\renewcommand*{\chapnumfont}{}
	\settowidth{\chapindent}{\chapnumfont 999}
	\renewcommand*{\printchaptername}{}
	\renewcommand*{\chapternamenum}{}
	\renewcommand*{\afterchapternum}{}
	\renewcommand*{\printchaptertitle}[1]{%
		\parbox[c][8\baselineskip][c]{\textwidth}{
			{\raggedright\fontsize{25}{25}\selectfont\color{azul}{\sffamily\nohyphens{##1}}\par}
			\vspace{.618\baselineskip}
			%por \@chapterauthor
		}%
		\begin{tikzpicture}[remember picture,overlay]
			\node[anchor=north west,fill=primario,xshift=-10pt,yshift=-2.5\baselineskip,minimum width=5cm,minimum height=8\baselineskip,rounded corners=10] 
				at (current page.north west) {\parbox{5cm}{\raggedleft\textcolor{white}{\includegraphics[height=3\baselineskip]{roseta-blanco}\hspace{30pt}}}};
		\end{tikzpicture}
	}
}

\makechapterstyle{Indexes}{%
	\setlength{\beforechapskip}{-3\baselineskip}
	\setlength{\afterchapskip}{\baselineskip}
	\renewcommand*{\chapnumfont}{}
	\settowidth{\chapindent}{\chapnumfont 999}
	\renewcommand*{\printchaptername}{}
	\renewcommand*{\chapternamenum}{}
	\renewcommand*{\afterchapternum}{}
	\renewcommand*{\printchapternum}{}
	\renewcommand*{\printchaptertitle}[1]{%
		\parbox[c][8\baselineskip][c]{\textwidth}{
			{\raggedright\fontsize{25}{25}\selectfont\color{azul}{\sffamily\nohyphens{##1}}\par}
			%\vspace{.618\baselineskip}
			%\small\itshape por \@chapterauthor
		}%
		\begin{tikzpicture}[remember picture,overlay]
			\node[anchor=north west,fill=primario,xshift=-10pt,yshift=-2.5\baselineskip,minimum width=5cm,minimum height=8\baselineskip,rounded corners=10] 
				at (current page.north west) {\parbox{5cm}{\raggedleft\textcolor{white}{\includegraphics[height=3\baselineskip]{roseta-blanco}\hspace{30pt}}}};
		\end{tikzpicture}
	}
}

% ÍNDICES (CAPÍTULOS, ÍNDICE DE FIGURAS, ÍNDICE DE CUADROS) %
\setlength{\cftbeforechapterskip}{.618\baselineskip}
\setlength{\cftchapterindent}{.618\baselineskip}

\newlength{\mylen}
\settowidth{\mylen}{\bfseries 999}

\renewcommand*{\cftchapterfont}{\color{azul}}
\renewcommand*{\cftchapterpresnum}{\color{naranja}\hfill}
\renewcommand*{\cftchapteraftersnum}{\color{azul}}
\renewcommand*{\cftchapteraftersnumb}{\color{azul}\hspace{6pt}|\hspace{6pt}}
\renewcommand*{\cftchapternumwidth}{\mylen}
\renewcommand*{\cftchapterformatpnum}{\color{azul}\bfseries}
%\renewcommand*{\cftchapterafterpnum}{\par\hspace{7.5pt}\normalfont\color{azul}\itshape\@chapterauthor}

\renewcommand*{\cftfigurefont}{\color{azul}}
\renewcommand*{\cftfigurepresnum}{color{naranja}\hfill}
\renewcommand*{\cftfigureaftersnum}{\color{azul}\hspace{7.5pt}|}
\renewcommand*{\cftfigurenumwidth}{22pt}

\renewcommand*{\cfttablefont}{\color{azul}}
\renewcommand*{\cfttablepresnum}{color{naranja}\hfill}
\renewcommand*{\cfttableaftersnum}{\color{azul}\hspace{7.5pt}|}
\renewcommand*{\cfttablenumwidth}{22pt}


%%%%%%%%%%%%%
% SECCIONES %
\titleformat{name=\section,page=even}%[leftmargin]
{\filright}%\filleft\centering
{\sffamily\Large\bfseries\color{primario}\thesection}
{.75em}
{\sffamily\Large\color{azul}\bfseries}

\titleformat{name=\section,page=odd}%[leftmargin]
{\filright}%\filright\centering
{\sffamily\Large\bfseries\color{primario}\thesection}
{.75em}
{\sffamily\Large\color{azul}\bfseries}

\titlespacing{\section}{0\marginparwidth}{.618cm plus .1ex minus .2ex}{5pt}

% ÍNDICE (SECCIONES) %
\titlecontents{section}[2cm]
{\small}
{\color{naranja}\contentslabel{.75cm}\color{azul}}
{}
{\titlerule*[1pc]{.}\color{azul}\contentspage}


%%%%%%%%%%%%%%
% SUBSECCIÓN %
\titleformat{name=\subsection,page=even}{leftmargin}%[drop]
{\filleft}%\filleft\centering\filleft
{\sffamily\Large\color{primario}\thesubsection}
{.75em}
{\sffamily\Large\color{azul}}

\titleformat{name=\subsection,page=odd}[leftmargin]%[drop]
{\filleft}%\filleft\centering\filleft
{\sffamily\Large\color{primario}\thesubsection}
{.75em}
{\sffamily\Large\color{azul}}

\titlespacing{\subsection}{3\marginparwidth}{.25cm plus .1ex minus .2ex}{15pt}

% ÍNDICE (SUBSECCIONES) %
\titlecontents{subsection}[2.85cm]
{\small}
{\color{naranja}\contentslabel{.85cm}\color{azul}\hspace{.1cm}}
{}
{\titlerule*[1pc]{.}\color{azul}\contentspage}


%%%%%%%%%%%%%%%%%%%
% SUBSUBSECCIONES %
\renewcommand{\thesubsubsection}{\roman{subsubsection}.}
\titleformat{name=\subsubsection,page=even}[leftmargin]
{\filleft}%\filleft\centering\filleft
{\sffamily\color{primario}\thesubsubsection}
{.75em}
{\sffamily\color{primario}}

\titleformat{name=\subsubsection,page=odd}[leftmargin]
{\filleft}%\filleft\centering\filleft
{\sffamily\color{primario}\thesubsubsection}
{.75em}
{\sffamily\color{primario}}

\titlespacing{\subsubsection}{3\marginparwidth}{.1cm plus .1ex minus .2ex}{15pt}

% ÍNDICE (SUBSUBSECCIONES) %
\titlecontents{subsubsection}[3.75cm]
{\footnotesize}
{\color{naranja}\contentslabel{27pt}\color{azul}\hspace{.25cm}}
{}
{\titlerule*[1pc]{.}\color{azul}\contentspage}


%%%%%%%%%%%%
% PÁRRAFOS %
\titleformat{name=\paragraph,page=even}[runin]
{}
{}
{0pt}
{\footnotesize\color{primario}\MakeUppercase}

\titleformat{name=\paragraph,page=odd}[runin]
{}
{}
{0pt}
{\footnotesize\color{primario}\MakeUppercase}

\titlespacing{\paragraph}{0cm}{.0cm plus .1ex minus .2ex}{.2cm}





%%%%%%%%%%%%%%%%%%%%
%%% 7. FOOTNOTES %%%
%%%%%%%%%%%%%%%%%%%%
\usetikzlibrary{decorations.markings}
\newcommand{\dhorline}[3][0]{%
    \tikz[baseline]{\path[decoration={markings,
      mark=between positions 0 and 1 step 2*#3
      with {\node[fill, circle, minimum width=#3, inner sep=0pt, anchor=south west] {};}},postaction={decorate}]  (0,#1) -- ++(#2,0);}}

\renewcommand*{\footnoterule}{%
\kern-3pt%
\color{azul} \hrule width \columnwidth
\kern 2.6pt}

\renewcommand{\@makefntext}[1]{%
	\color{azul}\noindent\textsuperscript{\color{primario}\@thefnmark}~#1\color{azul}
}
\renewcommand*{\@makefnmark}{\hbox{\color{primario}\textsuperscript{\@thefnmark}}}

% Conteo contínuo a través de capítulos %
\RequirePackage{chngcntr}
\counterwithout{footnote}{chapter}





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 8. LISTAS, DESCRIPCIONES, ENUMERACIONES, ETC. %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\RequirePackage{enumitem}
\setlist[description]{font=\color{primario}\MakeUppercase,before=\small,
	itemsep=.0\baselineskip,itemindent=-20pt,leftmargin=35pt,rightmargin=0pt,topsep=0pt,labelsep=5pt}
\setlist[enumerate]{font=\color{primario},before=\small,
	itemsep=.0\baselineskip,itemindent=0cm,leftmargin=20pt,rightmargin=0pt,topsep=0pt,labelsep=5pt}
\setlist[itemize]{font=\color{primario},before=\small,
	itemsep=.0\baselineskip,itemindent=0cm,leftmargin=20pt,rightmargin=0pt,topsep=0pt,labelsep=5pt}
%\RequirePackage[labelfont={bf,sc},font={footnotesize,sc},labelformat=parens,labelsep=space]{subcaption}





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 9. TABLAS, FIGURAS Y ECUACIONES %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\RequirePackage{multirow} 								% Tablas multifila
\RequirePackage{multicol}								% Tablas multicolumna
\RequirePackage{verbatimbox}
%	\creflabelformat{equation}{#2\textup{#1}#3}

\def\toprule{\arrayrulecolor{primario}\noalign{\ifnum0=`}\fi
  \@aboverulesep=\abovetopsep
  \global\@belowrulesep=\belowrulesep %global cos for use in the next noalign
  \global\@thisruleclass=\@ne
  \@ifnextchar[{\@BTrule}{\@BTrule[0.3ex]}}
\def\midrule{\arrayrulecolor{primario}\noalign{\ifnum0=`}\fi
	\@aboverulesep=\aboverulesep
	\global\@belowrulesep=\belowrulesep
	\global\@thisruleclass=\@ne
	\@ifnextchar[{\@BTrule}{\@BTrule[0.1ex]}}
\def\bottomrule{\arrayrulecolor{primario}\noalign{\ifnum0=`}\fi
	\@aboverulesep=\aboverulesep
	\global\@belowrulesep=\belowbottomsep
	\global\@thisruleclass=\@ne
	\@ifnextchar[{\@BTrule}{\@BTrule[0.3ex]}}


%%%%%%%%%%%%%%%%%%%%%%%
% COLUMNAS AJUSTABLES %
\newcolumntype{C}[1]{>{\centering\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
\newcolumntype{L}[1]{>{\raggedright\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}
\newcolumntype{R}[1]{>{\raggedleft\let\newline\\\arraybackslash\hspace{0pt}}m{#1}}

\setfloatadjustment{table}{\centering\footnotesize}
\setfloatadjustment{figure}{\centering}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 10. SIDECAPTION, NOTAS Y FUENTES %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%
%% SIDECAPTION %%
\renewcommand{\counterwithin}{\@ifstar{\@csinstar}{\@csin}}
\setsidecaps{15pt}{3\marginparwidth}
\captionnamefont{\color{primario}\bfseries\small}
\captiontitlefont{\color{azul}\small}
\captiondelim{.\space}
\precaption{\color{azul}\rule{\linewidth}{0pt}\par}
\postcaption{\color{azul}\rule{\linewidth}{0pt}\par}
\setsidecappos{c}
\sidecapmargin{left}
\setlength{\abovecaptionskip}{0\baselineskip}
\setlength{\belowcaptionskip}{0\baselineskip}
\strictpagechecktrue


\renewcommand*{\sidecapstyle}{%
\ifscapmargleft%
%\setsidecaps{.1\marginparwidth}{.1\marginparwidth}
\captionstyle{\raggedleft}%\raggedright\centering\raggedleft
\else%
%\setsidecaps{.1\marginparwidth}{.1\marginparwidth}
\captionstyle{\raggedleft}%\raggedright\centering\raggedleft
\fi}
%\strictpagecheck



%%%%%%%%%%%%%%%%%
%%% 11. FINAL %%%
%%%%%%%%%%%%%%%%%
\renewcommand{\bibfont}{\footnotesize}
\AtEndDocument{
	\clearpage
	\chapterstyle{Indexes}
	\pagestyle{ciepFront}
	\backmatter

	% ACRÓNIMOS %
	\ifdefined\maindoc
		\ifnum\@acronimos=1
			\small\input{CIEP/acronimos}
		\fi
		\clearpage
	\else
		\ifnum\@acronimos=1
			\small\input{../CIEP/acronimos}
		\fi
		\clearpage		
	\fi

	% ÍNDICE DE FIGURAS (GRÁFICAS) %
	\ifnum\@nofiguras=0
		\listoffigures
		\clearpage
	\fi

	% ÍNDICE DE CUADROS (TABLAS) %
	\ifnum\@nocuadros=0
		\listoftables
		\clearpage
	\fi

	% BIBLIOGRAFÍA %
	\ifdefined\maindoc
		\bibliography{CIEP/bibliografia}
	\else
		\bibliography{../CIEP/bibliografia}
	\fi

	% CONTRAPORTADA %
	\cleartooddpage[	\pagestyle{empty}]\pagestyle{empty}
	\ifnum\@noportada=0
		\begin{tikzpicture}[remember picture,overlay]
			\node[anchor=center,xshift=-.5pt] at (current page.center) 
				{\includegraphics[width=\paperwidth]{contraportada}};
		\end{tikzpicture}
	\fi
}