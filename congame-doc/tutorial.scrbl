#lang scribble/manual

@; TODO
@; Be consistent in the use of 'I', 'We', 'you'

@title{Conscript Tutorial}

You will create a simple study that gets some information from people (their age, their height), elicits a probability about some belief from them, and finally asks them to choose their favorite color between orange and blue, which will determine how the final page looks.

@section{Create researcher account}

To follow along with this tutorial, you need to create an account with the 'researcher' or 'admin' roles on a @tech{congame} server. To do so, create an account on your @tech{congame} server, then in your database, set the researcher role in the database. In postgres:

@codeblock|{
  UPDATE users SET roles = '{researcher}' WHERE ID = <id-of-your-user>;
}|

If you have a researcher or admin role, you will see navigation for 'Admin' and 'Jobs'.

@section{The first study}

To start, note that @tech{conscript} is based on @tech{scribble} syntax: this means that all operators start with an @"@", followed by the name of the operator, followed either by square brackets ("[]") or curly brackets ("{}") that contain additional content. To get started, let us create a @tech{conscript} study that displays a single page with some text. To do so, store the following text in @filepath{tutorial.scrbl}:

@codeblock|{
@step[start]{
    @h1{The Beginning is the End}}

@study[
  tutorial1
  #:transitions
  [start --> start]]
}|

This code defines a @tech{step} named 'start', and a @tech{study} named 'tutorial', which starts with a single step and ends with a single step. You can upload the code to your congame server as follows, where you have to provide the name of the study that should be run as the @emph{Study ID}. To do so, follow these steps:

@itemlist[
  @item{Log in to your researcher account}
  @item{Go the @emph{Admin} page}
  @item{Click on @emph{New Study}}
  @item{Provide a @emph{Name} such as "Tutorial <your name>"}
  @item{As @emph{Type}, choose @emph{DSL}}
  @item{As @emph{Study ID}, take the ID of the study from your source code, @emph{tutorial1} if you used the code above}
  @item{As @emph{DSL source}, browse for your @filepath{tutorial.scrbl} file}
  @item{Click the @emph{Create} button}
]

If everything went well, you will see a page with instances of your tutorial study, which should be none. Create a @emph{New Instance}. You can give it whatever name you want, and don't need to add any other field. Simply click @emph{create}.

Now when you go back to the @emph{Dashboard}, you should see your study with the name you gave it as an instance. You can now enroll in that study yourself (for testing) and should see the first page. Congratulations!

@section{Multi-Step Studies}

Having a study that consists of a single page isn't very interesting. Let us add two more steps, one intermediate one, where we will ask for the name and age, and a final one to thank the person by name.

There are several new parts in this multi-step study:

@itemize[
  @item{How to put multiple steps in sequence}
  @item{How to write a form}
  @item{How to get and use data that is stored}
]

Suppose that we have three steps, creatively named @racket[step1], @racket[step2], and @racket[step3]. To create a study with these steps in order, with @racket[step3] the final one, we write:

@codeblock|{
  @study[
    three-steps
    #:transitions
    [step1 --> step2 --> step3 --> step3]]
}|

The first argument of @racket[study] is the ID of the study. It must be followed by the keyword @racket[#:transitions], followed by one or more transition entries enclosed in square brackets. The simplest type of transition entry is a sequence of step IDs connected by @racket[-->]'s, such as @racket[step1 --> step2]. The arrow indicates that after completing @racket[step1], we transition to @racket[step2].

Note that every step has to explicitly define a transition, even if it is meant to be the final step. Thus to make @racket[step3] the final step, we have to write that it transitions to itself: @racket[step3 --> step3].

The primary goal of studies is to collect data from participants, and @racket[form]s are the main way of getting input from participants. The simplest forms will contain one or more @racket[input] fields, and a @racket[submit-button]. The input field for free-form text answers (e.g. when asking for a name) is @racket[input-text]. In order to be able to store the answer provided by the user when the form is submitted, we need to provide an ID for the data:

@codeblock|{
  @input-text[first-name]{What is your name?}
}|

This input field ensures that the answer the user provided is a string and stores it as such with the ID @racket[first-name]. A form to get the first name and the age of a person will thus look as follows:

@codeblock|{
  @form{
    @input-text[first-name]{What is your first name?}
    @input-number[age]{What is your age (in years)?}
    @submit-button[]}
}|

It is important not to confuse square ("[]") and curly ("{}") brackets. The main difference is that curly brackets interpret their content as a string by default (although they correctly expand other @"@" forms, such as @code|{@get}| that we'll see later). Therefore much of what users see will be in curly brackets. Square brackets on the other hand interpret their content as data: therefore identifiers of studies and steps, numbers, or keys to extract data should be enclosed in square brackets. Square brackets are optional, but when used have to come before curly brackets (which are also optional).

Once a study stores data, we can get it by using @code|{@get}|. Suppose the user provided their first name, then we can get the value with @code|{@get['first-name]}| -- note the single quote (') in front of first-name, which identifies it as a @emph{symbol} rather than as the object named @racket[first-name].

Putting all of this together, we can create our first multi-step study by updating @filepath{tutorial.scrbl} as follows:

@codeblock|{
@step[description]{
  @h1{The study}

  Welcome to our study. In this study, we will ask for

  @ul{
    @li{your first name}
    @li{your age}}

  @button{Start Survey}
}

@step[age-name-survey]{
  @h1{Survey}

  @form{
    @input-text[first-name]{What is your first name?}
    @input-number[age]{What is your age (in years)?}
    @submit-button[]}
}

@step[thank-you]{
  @h1{Thank you @(ev (get 'first-name))}

  Thank you for participating in our survey @(ev (get 'first-name))!
}

@study[
  tutorial2
  #:transitions
  [description --> age-name-survey --> thank-you --> thank-you]]
}|

We have to update the code on the congame server to reflect these changes. Go to the admin page, and follow these steps to update the study code and the study run for tutorial:

@itemize[
  @item{Click on your existing study instance}
  @item{Click on @emph{Edit DSL}}
  @item{Change the DSL ID to @emph{tutorial2}, since we call the new study @emph{tutorial2}}
  @item{Pick the updated version of @filepath{tutorial.scrbl}}
  @item{Click @emph{Update}}]

Try to resume the study. If you did the the @emph{tutorial1} study, you should now see an error. This is because when you did @emph{tutorial1}, you progressed to the step with the ID @emph{start}. Since such a step does not exist in @emph{tutorial2}, you get an error.

To fix this, you have to clear the progress of your user for this study instance. Go to the admin page of the tutorial instance (@emph{Admin}, click on the name of your tutorial instance). Towards the bottom, you will see a list of instances under @bold{Instance Name}. Click on your instance. At the bottom of the next page is the list of participants who have enrolled in this study. Click on your ID (which you can identify by the email if you enrolled from your congame server). Then click on @emph{Clear participant progress}. (Note: it may look like there was no progress, if the table is empty. That's because the progress shows only additional data that you store explicitly, not implicit progress such as the current step you are on.)

Now you can bo back to the dashboard and go through the study. Congratulations, this is your first survey in @tech{conscript}!

@section{Using standard functions}

Basic conscript is purposefully underpowered and comes with a small number of built-in features. Many @tech{Racket} functions are provided by default, and we will add more as they become useful.

To illustrate this, let us add a display of the person's age to the previous study. It may seem straightforward, and you might try to do change the code of the final @racket[thank-you] step as follows:

@codeblock|{
@step[thank-you]{
  @h1{Thank you, @(ev (get 'first-name))}

  Thank you for participating in our survey, @(ev (get 'first-name))! You are the most awesome @(ev (get 'age))-year old!
}
}|

You might expect this to display the age on the page. Instead, you are likely to find that the final page does not display the age at all, and you see only "You are the most awesome &-year old!" (or some other strange character in place of the &) instead. What is going on?

What is going on is that when we are storing a number, we are storing a number and not a string! So when we use @code|{@(ev (get 'age))}| to display the age, we are providing the age as a number and not as a string, and since numbers are encoded differently, this leads to the strange display you get. To fix this, all we need to do is to convert numbers to strings before displaying them. Fortunately, @racket[number->string] is provided by default. To use it, just call it inside an @code|{@(ev ...)}| call:

@codeblock|{
@step[thank-you]{
  @h1{Thank you, @(ev (get 'first-name))}

  Thank you for participating in our survey, @(ev (get 'first-name))! You are the most awesome @(ev (number->string (get 'age)))-year old!
}
}|

@section{Studies with Logic}

We often want to respond to participants, whether it is to display different messages as we progress, or based on their answers. We will now create a few studies using some of the programming features that conscript provides.

First, let us count down from 10 to 0 and display the pages to the
user. We could of course define a separate step for each number,
calling them @racket[step10] down to @racket[step0] and then string
them together as @tt{step10 --> ... --> step0}, but that is
tedious. Instead, for every user, let us store the value of
@racket[counter] and every time the user progresses, we decrease the
value of @racket[counter] and display it on the screen. To store a
value for a user, we use @code[#:lang "scribble/manual"]|{@put[id value]}|.

The most important building block for this is the @code[#:lang
"scribble/manual"]|{@action}| operator. Whenever you want to change or update
some value or variable in conscript, you have to define a named @tt{action}
which will be evaluated when called. In the case of the countdown, we need to do
two things. First, we need an action that initializes the user's counter to 10;
second, we need an action that decreases the counter by 1 when called:


@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@action[initialize-counter]{
  @(ev (put 'counter 10))
}

@action[decrement-counter]{
  @(ev (put 'counter (sub1 (get 'counter))))
}
}|

Here we use @racket[sub1], which subtracts 1 from its argument. Later we'll see another way to do basic arithmetic.

Next, we need to call the @tt{action}s in the right places. There are two places where you can use actions: before a step is displayed by using @code|{@step[step-name #:pre action-id]}|; or after a button click (and before the next step is executed) using @code|{@button[#:action-id action-id]{Next}}|. We will the button approach here:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@; Here goes the above code defining the actions
@; ...

@step[description]{
  @h1{The countdown is about to begin}

  @button[#:action initialize-counter]{Start Countdown}
}

@step[show-counter]{
  @h1{@(ev (number->string (get 'counter)))}

  @button[#:action decrement-counter]{Count down!}
}

@study[
  countdown
  #:transitions
  [description --> show-counter]
  [show-counter --> show-counter]
]
}|

While this works, it has a fatal flaw. We keep counting down forever and ever. Instead, we would like to stop once we hit 0, and display the launch page.

@section{Conditions}

In order to stop once the counter hits 0, we need to change the transitions. Specifically, we want to transition to the @tt{launch} step when the counter is 0, and otherwise keep displaying the @tt{show-counter} step. To do so, we use @racket[cond] inside a transition, which has to be wrapped in something mysterious called a @racket[lambda]:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@step[launch]{
  @h1{Study launched!}
}

@study[
  countdown
  #:transitions
  [description --> show-counter
               --> @(ev (lambda ()
                          (cond
                            [(= (get 'counter) 0)
                             'launch]
                            [else
                             'show-counter])))]
  [launch --> launch]
]
}|

For now, ignore what the @racket[lambda] part does, simply type it and run with it. As for the @racket[cond], it is relatively straightforward: it consists of two or more clauses that are wrapped in square brackets ('[]'). Each clause starts with a condition, such as @tt{(= (get 'counter) 0)}, which checks whether the value of @tt{'counter} is 0 or not. If the condition holds, then the transition continues to the step at the end of the clause, here @tt{'launch}, which has a quote (') in front of it. (Note: this will soon change, as we will write it @tt{(goto launch)}, with no quote (') in front of launch.)

The final clause must always start with the keyword @racket[else], which is a catchall for the case where none of the conditions in previous clauses were met.

@section{CSS with #:style}

On the launch page, let us highlight the font of "Study launched!" in red, which requires that we change the following CSS rule (CSS stands for @emph{Cascading Style Sheet}) with "h1 { color: red; }".
}|

In @tech{conscript}, we can add CSS styles to @tt{div} tags by using the @tt{#:style} keyword argument. To change the @tt{h1} tag, we need to wrap it in a @tt{div} tag and style it accordingly:

@codeblock|{
@step[launch]{
  @div[#:style "color: red;"]{
    @h1{Study launched!}
  }
}
}|

To add multiple style properties, we separate them by a semicolon:

@codeblock|{
@step[launch]{
  @div[#:style "color: red; font-size: 2rem;"]{
    @h1{Study launched!}
  }
}
}|

@section{Reusing steps and whole studies}

In many studies, it is useful to repeatedly measure the same thing: a willingness to pay, the mood, fatigue, and many others. In countdown, we saw one way of repeating a step that displays similar information again and again. Now we will see several other ways, including ones where we elicit information again and again. Note that one major problem we will have to deal with is how to name the values that we measure: if we always use the identifier @tt{'fatigue} to store how tired a person is, then we run the danger of overwriting it.

First, let us try to define a step and reuse it 3 times:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@step[description]{
  @h1{Fatigue Survey}

  In this study we will ask you three times how tired you are.

  @button{Start study}
}

@step[how-tired-are-you]{
  @h1{Fatigue question}

  @form{
    @input-number[fatigue #:min 1 #:max 5]{On a scale from 1 (very tired) to 5 (very awake), how tired are you?}
    @submit-button[]
  }
}

@step[done]{
  @h1{You are done!}

  Thank you for participating.
}

@study[
  three-fatigues
  #:transitions
  @; This will not work as expected
  [description --> how-tired-are-you --> how-tired-are-you --> how-tired-are-you --> done]
  [done --> done]
]
}|

The above does not work, as it is interpreted as saying that after the step @tt{how-tired-are-you} comes the step @tt{how-tired-are-you}, and the next arrow simply repeats this information again. We could add a counter as we did for countdown, but that will not work. When you look at the data in the database after submitting two or more answers, you will see that only a single answer (the last one) was stored. This problem persists when we use the counter.

One way to solve the problem is to define three separate steps that do the same thing, but store it in different values:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@step[how-tired-are-you1]{
  @h1{Fatigue question}

  @form{
    @input-number[fatigue1 #:min 1 #:max 5]{On a scale from 1 (very tired) to 5 (very awake), how tired are you?}
    @submit-button[]
  }
}

@step[how-tired-are-you2]{
  @h1{Fatigue question}

  @form{
    @input-number[fatigue2 #:min 1 #:max 5]{On a scale from 1 (very tired) to 5 (very awake), how tired are you?}
    @submit-button[]
  }
}

@step[how-tired-are-you3]{
  @h1{Fatigue question}

  @form{
    @input-number[fatigue3 #:min 1 #:max 5]{On a scale from 1 (very tired) to 5 (very awake), how tired are you?}
    @submit-button[]
  }
}

@study[
  three-fatigues
  #:transitions
  [description --> how-tired-are-you1
               --> how-tired-are-you2
               --> how-tired-are-you3
               --> done]
  [done --> done]
]
}|

This will work. But one of the more famous mottos in programming is @emph{Don't Repeat Yourself}, or @emph{DRY} for short. While one can overdo it with DRY, here we have literally had to repeat whole steps three times, and moreover manually needed to change the name of the step and of the value we want to store. Imagine a more complicated survey with 10 questions: we would have to change 10 names for each repetition, which is a recipe for disaster!

This brings us to one of the nicer features of conscript: we can reuse whole studies as substudies of a larger study. Moreover, substudies never overwrite data from other substudies  (unless you use advanced features, which require you being explicit about it). In our context, that means that if we define a study that saves a respondent's fatigue with the identifier @tt{'fatigue}, we can reuse it multiple times, and each saves its own identifier @tt{'fatigue}, leaving all the others alone.

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@; take the `description` and `done` steps from above
@; ...

@; Add the following
@step[how-tired-are-you]{
  @h1{Fatigue question}

  @form{
    @input-number[fatigue #:min 1 #:max 5]{On a scale from 1 (very tired) to 5 (very awake), how tired are you?}
    @submit-button[]
  }
}

@study[
  fatigue
  #:transitions
  [how-tired-are-you --> @(ev (lambda () done))]
]

@study[
  three-fatigues
  #:transitions
  [description --> [fatigue1 fatigue]
               --> [fatigue2 fatigue]
               --> [fatigue3 fatigue]
               --> done]
  [done --> done]
]
}|

This is the first time that we define two studies. Then we reuse the first study, named @tt{fatigue} three times in the second one, by using the following pattern for the transition: @tt{--> [<name-the-step> <study-to-run>]}, where the @emph{<name-of-the-step>} is what you want to call this step as part of the @tt{three-fatigues} study, while @tt{<study-to-run>} is the study that will be run. Hence we provide three different names, yet the same study each time, since we want to run the same study.

It is important that for the study that we want to use as a substudy that we add a transition at the end that looks as follows: @code|{@(ev (lambda () done))}|. This tells conscript that at this point it should leave the substudy and go back to the parent study.

@section{Intermezzo: Some exercises}

@bold{Exercise 1} The function @racket[rand] can be used to generate random numbers: @tt{(rand 10)} returns a random integer between 0 and 9. Use this to create the following study. Draw a random number between 0 and 9 for a person and store it. Now repeat the following steps three times:

@itemlist[
  @item{Elicit the person's belief that their number is greater than or equal to 5}
  @item{Pick a random number. Tell the person whether their number is larger than (or equal to) or smaller than this new random number, which you show them.}
]

For example, you might pick the random number 3 for them. Then you pick the numbers 6 ("Your number is smaller than 6"), 9 ("Your number is smaller than 9"), and 2 ("Your number is larger than (or equl to) 2").

@bold{Exercise 2} Pick an experiment from a paper of your choice. Stub out the experiment: this means that you create a page for every page of the experiment, but for pages that might require some interface (e.g. some game or an involved elicitation method), you simply write what would happen there and what functionality you need to be able to implement it.


@section{Studies involving multiple Participants}

Many studies involve participants who interact or affect each other: the dictator game, the public goods game, any study with markets, auctions, or negotiations. This requires also that we somehow share values across participants. While @racket{get} and @racket{put} provide a way to store values for a given participant, these values are private. This makes sense by default. Consider what would happen in the countdown study if two participants took the same study instance, and one participant has already progressed to the point where the counter is 3. Then the other participant would see the counter at 3 right from the start, which is clearly not the behavior we want.

We will start with a specific, but particularly useful feature that we can implement with multiple participants: an admin page for your study instance that only you (the owner of the study instance) can see. You can display information about the study there, whether about progress by participants or some summaries on their answers. For now, let us have a study where participants provide their name and age, and on the admin page we show how many participants have completed the study so far.

For this, we use the function @racket[current-participant-owner?], which returns true (@racket[#t]) when the current user is the owner of the instance, and false (@racket[#f]) otherwise.

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@; Same code as in tutorial 2 above for the steps of normal participants

@step[admin]{
  @h1{You reached the admin page!}
}

@study[
  survey-with-admin
  #:transitions
  [start --> @(ev (lambda ()
                    (cond [(current-participant-owner?) 'admin]
                          [else 'description])))]
  [admin --> admin]
  [description --> age-name-survey --> thank-you --> thank-you]]
}|

With this code, the owner of the study instance will see the start page, and after that the admin page and remain there. Study participants on the other hand will be guided to the normal study instead. Right now, the admin page doesn't provide any useful data. In order to share data from the participants with the owner, we need to use @racket[get/instance] and @racket[put/instance] instead of @racket[get] and @racket[put]. @racket[put/instance] stores the data in a way that we can access it with @racket[get/instance] from each participant. This also means that if two participants store something on an instance, they overwrite each others value. Therefore we have to make sure first get the old value, and then update it.

For now, all we want is to count how many participants completed the study, so every time a participant gets to the @tt{thank-you} page, we increment an @emph{instance-wide} counter by 1.

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@action[initialize-count-if-needed]{
  @(ev
    (begin
      (unless (get/instance 'participant-count #f)
        (put/instance 'participant-count 0))
      ))
}

@step[start]{
  @h1{Start page}

  @button[#:action initialize-count-if-needed]{Next}
}

@action[increment-participant-count]{
  @(ev
    (begin
      (define participant-count
        (get/instance 'participant-count))
      (put/instance 'participant-count (add1 participant-count))
    ))
}

@step[thank-you #:pre increment-participant-count]{
  @; old code
  @; ...
}

@step[admin]{
  @h1{Admin}

  Number of participants who completed the study: @(ev (get/instance 'participant-count))
}

}|

Next, let us implement a simple version of the dictator game to highlight a more complicated case of multi-person experiment. In our version, the person chooses between ($10, $0) and ($5, $5): i.e. taking $10 for themselves and nothing for the other, or giving $5 dollars to both.

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@action[assign-roles]{
  @(ev
    (begin
      (define next-pid
        (get/instance 'pid 0))
      (put 'pid next-pid)
      (cond [(even? next-pid) (put 'role "Dictator")]
            [else (put 'role "(Non-)Receiver")])
      (put/instance 'pid (add1 next-pid))
    ))
}

@step[start #:pre assign-roles]{
  @h1{You are in the role of @(ev (get 'role))}

  @button{Next}
}

@step[choice]{

  @form{
    @radios[
      payment-string
      '(
        ("10" . "$10 for yourself, $0 for the other perons")
        ("5"  . "$5 for yourself, $5 for the other person")
       )
    ]{Please choose which of these options you prefer:}
    @submit-button[]}
}

@action[check-answer]{
  @(ev
    (begin
      (define payments
        (get/instance 'payments (hash)))
      (define receiver-payment
        (hash-ref payments (get 'pid) #f))
      (cond [receiver-payment (put 'payment receiver-payment)]
            [else (put 'payment #f)])))
}

@step[wait]{

  @h1{Refresh this screen regularly}

  Check back later to see if your partner has made their choice yet.

  @button[#:action check-answer]{Check the answer}
}

@action[update-receiver-payment]{
  @(ev
     (begin
       @; We pair participant with id 1 with participant
       @; with id 0; participant with id 3 with participant with id 2;
       @; and so on
       (define payment
         (string->number (get 'payment-string)))
       (put 'payment payment)
       (define receiver-id
         (add1 (get 'pid)))
       (define receiver-payment
         (- 10 payment))
       (define current-payments
         (get/instance 'payments (hash)))
       (define new-payments
         (hash-set current-payments receiver-id receiver-payment))
       (put/instance 'payments new-payments)))
}

@step[display-dictator #:pre update-receiver-payment]{
  @h1{You will receive $@(ev (number->string (get 'payment)))}
}

@step[display-receiver]{
  @h1{You will receive $@(ev (number->string (get 'payment)))}
}

@study[
  baby-dictator
  #:transitions
  @; everyone
  [start --> @(ev (lambda () (cond [(even? (get 'pid)) 'choice]
                        [else 'wait])))]
  @; dictator
  [choice --> display-dictator]
  [display-dictator --> display-dictator]
  @; receiver
  [wait --> @(ev (lambda () (cond [(get 'payment #f) 'display-receiver]
                       [else 'wait])))]
  [display-receiver --> display-receiver]
]
}|

@section{Example Studies on Github}

You can find example studies on GitHub at @url{https://github.com/MarcKaufmann/congame/tree/master/congame-doc/conscript-examples} that illustrate a variety of features:

@itemlist[
  @item{how to include tables (tables.scrbl)}
  @item{the form input types available (all-inputs.scrbl)}
  @item{how to randomize participants into multiple treatments (assign-treatments.scrbl)}
  @item{how to use @code|{@refresh-every}| to wait for input from another player (wait-for-partner.scrbl)}
  @item{how to use html tags inside of @tt{(ev ...)} (tags-in-ev.scrbl)}
  @item{how to use images, and apply CSS styles to them with @code|{@style}|, @tt{#:style}, and @tt{#:class} (images.scrbl)}
]

@section{Randomizing participants into treatments}

While the example study on github provides an example for randomizing participants into treatments from scratch, you can use the function @racket[assigning-treatments] that you can use inside @tt{(ev ...)}. Thus the action that assigns treatments simply becomes:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@action[assigning-treatments]{
  @(ev
    (begin
      (define treatments
        (list
          'buyer 'buyer 'seller 'seller 'seller
          'observer 'observer 'observer 'observer 'observer))
      (assigning-treatments treatments)))
}
}|

This will randomize the order of the treatments and balance them across participants as they arrive. That means that in the case of 10 treatments (as in the example), every set of 10 participants is assigned to these 10 roles to ensure that we always have 2 buyers, 3 sellers, and 5 observers. The order in which they are assigned these roles is randomized.

This works by storing the treatment of the participant as a participant variable in @racket['role] and the set of treatments for the current group of participants as an instance variable in @racket['treatments]. Importantly, both of these variables are stored at the top level (@tt{(*root*)}), so they can be set and retrieved with @racket[get/global], @racket[put/global] for the @racket['role] and with @racket[get/instance/global] and @racket[put/instance/global] for the @racket['treatments] (you should not mess with the latter though). You can overrule these with @racket[#:treatments-key] and @racket[#:role-key]. So if you prefer storing the next set of treatments in @racket['my-treatments] and the treatment of the participant in @racket['treatment], then you need to change the action as follows:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@action[assigning-treatments]{
  @(ev
    (being
      (define treatments
        (list
          'buyer 'buyer 'seller 'seller 'seller
          'observer 'observer 'observer 'observer 'observer))
      (assigning-treatments treatments
                            #:treatments-key 'my-treatments
                            #:role-key       'treatment)))
}

@step[show-treatment]{
  @h1{Your treatment is @(ev (~a (get/global 'role)))}
}
}|

Notice the use of @racket[get/global] instead of @racket[get] to retrieve the role. This gets the value of @racket['role] stored at the top level study (@tt{(*root*)}), so that it is available from all substudies. Do not overuse the @tt{/global} versions of @racket[get] and @racket[put]. These set global variables, which is bad practice in general, as it leads to buggier code.

@section{Using buttons to jump to different steps}

You can use the @racket[#:to-step] keyword of buttons to override the default transition and instead jump to the step mentioned in the button as follows:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

step[a]{
  @h1{Step b}

  @button[#:to-step c]{To step c}
  @button[#:to-step d]{To step d}
  @button{Default transition (to step b)}
}

step[b]{
  @h1{Step b}
  @button{Next}
}

step[c]{
  @h1{Step c}
  @button{Next}
}

step[d]{
  @h1{Step d}
  @button{Next}
}

step[final]{
  @h1{Final}
}

@study[
  skippy
  #:transitions
  [a --> b --> c --> d --> final]
  [final --> final]
]
}|

This study would usually go from step a through d to the final page. But if we click on the appropriate button on the first page, we will instead directly jump to step c or d, overriding the defaults.

@section{Basic Arithmetic}

You can use basic arithmetic in @tt{ev} based on @tech{Racket}'s arithmetic, which means that it is infix based:

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@; Add two or more numbers
@(ev (+ 2 3))     @; 2 + 3
@(ev (+ 1 2 3 4)) @; 1 + 2 + 3 + 4

@; Subtract two numbers
@(ev (- 3 4)) @; 3 - 4

@; Multiply two or more numbers
@(ev (* 2 3))   @; 2 * 3
@(ev (* 2 -3))  @; 2 * (-3)

@; Divide
@(ev (/ 9 3))   @; 9 / 3 => 3
@(ev (/ 7 2))   @; 7 / 2 => the fraction 7/2!
@(ev (/ 7 2.0)) @; 7 / 2.0 => floating point 3.5

@; compute mean of 4 numbers
@(ev (/ (+ 1 2 3 4) 4.0))

@; Get the remainder or quotient
@(ev (remainder 7 2)) @; => 1
@(ev (quotient 7 2))  @; => 3
}|

If you want to include it in html markup, don't forget to transform the number to a string by using either @racket[number->string] or @racket[~a] (which turns every input into a string, so also works for symbols (@tt{'age}) or lists or other items):

@codeblock[#:keep-lang-line? #f]|{
#lang scribble/manual

@h1{Twice your age is @(ev (number->string (* 2 (get 'age))))}

Your remaining life expectancy is @(ev (~a (- 80 (get 'age)))).
}|
