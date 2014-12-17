var TweetItem = exports.TweetItem = React.createClass({
  getInitialState: function() {
    var tweet = this.props.tweet || {};
    var like_count = tweet.like_count;
    var unlike_count = tweet.unlike_count;
    return {like_count: like_count, unlike_count: unlike_count};
  },
  handleLike: function() {
    var self = this;
    if (!isLogin()) {return;}
    $.post("/api/tweets/" + this.props.tweet.tweet_id + '/like', function(data) {
      self.setState(data);
    });
  },
  handleUnLike: function() {
    var self = this;
    if (!isLogin()) {return;}
    $.post("/api/tweets/" + this.props.tweet.tweet_id + '/unlike', function(data) {
      self.setState(data);
    });
  },
  handleFavorite: function() {
    var self = this;
    if (!isLogin()) {return;}
    $.post("/api/tweets/" + this.props.tweet.tweet_id + '/favorite', function(data) {
      var fav = data.favorite? "fav": "unfav";
      self.setState({favorite: fav});
    });
  },
  handleDelete: function(evt) {
    var self = this;
    if (!isLogin()) {return;}
    notify('确定删除？', function() {
      $(self.getDOMNode()).hide();
      $.ajax("/api/tweets/" + self.props.tweet.tweet_id, {method: 'DELETE'}).done(function(data) {});
    });
  },
  render: function() {
    var tweet = this.props.tweet || {};
    var user = tweet.user || {};
    var like_count = this.state.like_count;
    if (!like_count)  {
      if (like_count !== 0) {
        like_count = tweet.like_count || 0;
      }
    }
    var unlike_count = this.state.unlike_count;
    if (!unlike_count) {
      if (unlike_count !== 0) {
        unlike_count = tweet.unlike_count || 0;
      }
    }
    var favorite = 'unfav';
    if (tweet.favorite) {
      favorite = 'fav'
    }
    favorite = this.state.favorite || favorite;

    var file = '';
    if (tweet.file) {
      file = <FileItem file={tweet.file} />;
    }

    var avatar;
    if (tweet.user && tweet.user.avatar) {
      avatar = <FileItem file={tweet.user.avatar} />;
    } else {
      avatar = <img src='/static/images/human.png' />
    }

    var entryBtn = "";
    if (config.user.user_id == user.user_id) {
      entryBtn = (
          <div className="entry-btn">
            <button className="delBtn" onClick={this.handleDelete}>删除</button>
          </div>
      );
    }

    var createdAt = DateFormat.format.date(new Date(tweet.created_at), '发布于 yyyy-M-dd HH:mm:ss');

    return (
      <article className="tweetItem">
        <header className="entry-header">
          <div className="avatar">
            {avatar}
          </div>
          <h3 className="entry-title">
            <a href={"/users/" + user.user_id} title={user.username}>{user.username}</a>
          </h3>

          <div className="entry-meta">
            <time className="entry-date">{createdAt}</time>
          </div>
          {entryBtn}
        </header>

        <div className="entry-content clearfix">
          <p>
            {tweet.text}
          </p>
          {file}
        </div>
        <div className="entry-status">
          <button className="like" onClick={this.handleLike}>{like_count}</button>
          <button className="unlike" onClick={this.handleUnLike}>{unlike_count}</button>
          <button className={favorite} onClick={this.handleFavorite}></button>
          <div className="right">
            <a href={"/tweets/" + tweet.tweet_id + "#comment"}>
              <button className="comment">{tweet.comment_count}</button>
            </a>
          </div>
        </div>
      </article>
    );
  }
});


var TweetForm = exports.TweetForm = React.createClass({
  handleSubmit: function(e) {
    e.preventDefault();
    if (!isLogin()) {return;}
    var text = this.refs.text.getDOMNode().value.trim();
    var file_id = this.refs.file_id.getDOMNode().value.trim();
    if (!text) {
      return;
    }
    $.post("/api/tweets", {text: text, file_id: file_id}, function(data) {
      console.log(data);
      $(".choose-file").text("选择图片");
    });
    this.refs.text.getDOMNode().value = '';
    this.refs.file_id.getDOMNode().value = '';
    return;
  },
  handleFocus: function() {
    $('.tweetForm .placeholder').hide();
  },
  handleBlur: function() {
    var text = this.refs.text.getDOMNode().value.trim();
    if (!text) {
      $('.tweetForm .placeholder').show();
    }
  },
  render: function() {
    return (
      <form className="tweetForm clearfix" onSubmit={this.handleSubmit}>
        <input ref="file_id" type="hidden" id="tweetFile" />
        <div className="placeholder">把好玩的图片，好笑的段子或糗事发到这里，接受千万网友的拜模吧！ </div>
        <textarea ref="text" onFocus={this.handleFocus} onBlur={this.handleBlur}> </textarea>
        <input type="submit" value="发布" className="clearfix" />
      </form>
    );
  }
});


var TweetList = exports.TweetList = React.createClass({
  render: function() {
    var tweetNodes = this.props.tweets.map(function(tweet, index) {
      return <TweetItem tweet={tweet} />
    });
    return (
      <div className="tweetList">
      {tweetNodes}
      </div>
    );
  }
});


var TweetBox = exports.TweetBox = React.createClass({
  loadTweets: function(page) {
    var self = this;
    var url = config.api;
    page = page || config.current;
    if (page > 1) {
      var limit = config.limit || 10;
      url = url + "?page=" + (page - 1) + "&limit=" + limit;
    }
    $.get(url, function(data) {
      self.setState(data);
    });
  },
  getInitialState: function() {
    return {tweets: config.tweets, current: config.current, total: config.total, limit: config.limit};
  },
  componentDidMount: function() {
  },
  render: function() {
    return (
      <div className="container">
        <TweetList tweets={this.state.tweets} />
        <Pagenavi current={this.state.current} total={this.state.total} limit={this.state.limit} onPageClick={this.loadTweets} />
      </div>
    );
  }
});


