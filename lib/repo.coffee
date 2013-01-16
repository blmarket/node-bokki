_ = require 'underscore'
path = require 'path'
step = require 'step'
gitteh = require 'gitteh'

createRepo = (path, callback) ->
  class Repo
    constructor: (@repo) ->

    trackCommit: (sha, count, onItem, onEnd) ->
      return onEnd(null) if count == 0 || !sha
      @repo.object sha, 'commit', (err, commit) =>
        return onEnd(err) if err
        onItem null, commit
        @trackCommit commit.parents[0], count-1, onItem, onEnd

    resolveObject: (sha, path, callback) ->
      return callback null, null if !path
      @repo.object sha, 'tree', (err, tree) =>
        return callback(err) if err
        pick = _.find(tree.entries, (item) -> item.name == path[0])
        path.shift()
        return callback(new Error("no such object")) if !pick
        return callback(null, pick) if path.length == 0
        @resolveObject pick.id, path, callback

    test: (refname, path, callback) ->
      @repo.reference refname, null, (err, res) =>
        return callback(err) if err

        list = []
        @trackCommit res.target, 1000, (err, item) =>
          return callback(err) if err
          @resolveObject item.tree, _.clone(path), (err, res) ->
            # Err, no result or there exists same object...
            return if err || !res || (list.length > 0 && res.id == list[0].id)
            list.unshift res
        , (err) ->
          callback err, list

  gitteh.openRepository path, (err, repo) ->
    return callback null, new Repo(repo)

module.exports.createRepo = createRepo
